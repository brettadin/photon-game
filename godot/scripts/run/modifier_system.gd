extends Node
class_name RunModifierSystem

const DATA_DIR := "res://data/modifiers"
const ModifierCallback := preload("res://scripts/run/modifier_callback.gd")
const PlayerAvatar := preload("res://scripts/player/player_avatar.gd")
const UnlockManager := preload("res://scripts/progression/unlock_manager.gd")
const ParticleClassDefinition := preload("res://scripts/classes/particle_class.gd")

signal theme_changed(theme_id: StringName, details: Dictionary)
signal stage_modifiers_applied(stage_index: int, modifier_ids: Array)
signal modifier_applied(modifier_id: StringName, details: Dictionary)
signal modifier_removed(modifier_id: StringName)

class ModifierProfileSource:
    extends RefCounted

    var modifier_id: StringName

    func _init(id: StringName) -> void:
        modifier_id = id

var _rng := RandomNumberGenerator.new()
var _player: PlayerAvatar
var _unlock_manager: UnlockManager

var _modifiers_by_id: Dictionary = {}
var _themes: Array[Dictionary] = []
var _class_boons_by_tag: Dictionary = {}
var _class_banes_by_tag: Dictionary = {}

var _active_theme: Dictionary = {}
var _active_stage_modifiers: Array[StringName] = []
var _active_records: Dictionary = {}
var _current_stage_index: int = -1
var _current_class_id: StringName = &""
var _current_class_tags: Array[StringName] = []

func _ready() -> void:
    _rng.randomize()
    load_data()

func load_data() -> void:
    _modifiers_by_id.clear()
    _themes.clear()
    _class_boons_by_tag.clear()
    _class_banes_by_tag.clear()
    var dir := DirAccess.open(DATA_DIR)
    if dir == null:
        push_warning("RunModifierSystem: Unable to open modifier data directory %s" % DATA_DIR)
        return
    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if not dir.current_is_dir() and file_name.to_lower().ends_with(".json"):
            _load_data_file("%s/%s" % [DATA_DIR, file_name])
        file_name = dir.get_next()
    dir.list_dir_end()

func set_player(player: PlayerAvatar) -> void:
    _player = player

func set_unlock_manager(manager: UnlockManager) -> void:
    _unlock_manager = manager

func on_run_started(class_data: Dictionary, particle_class: ParticleClassDefinition) -> void:
    _clear_all_modifiers()
    _resolve_class_identity(class_data, particle_class)
    var theme := _roll_theme()
    if theme.is_empty():
        _active_theme = {}
        emit_signal("theme_changed", StringName(), {})
    else:
        _activate_theme(theme)
    on_stage_advanced(0, {"phase": "run_start"})

func on_stage_advanced(stage_index: int, context: Dictionary = {}) -> void:
    _clear_stage_modifiers()
    _current_stage_index = stage_index
    var applied: Array[StringName] = _roll_stage_modifiers(stage_index, context)
    _active_stage_modifiers = applied
    _record_stage_combo()
    _call_stage_callbacks(stage_index, context)
    emit_signal("stage_modifiers_applied", stage_index, applied.duplicate())

func get_active_theme() -> Dictionary:
    return _active_theme.duplicate(true)

func get_active_modifiers() -> Array[StringName]:
    return _active_stage_modifiers.duplicate()

func _load_data_file(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_warning("RunModifierSystem: Unable to read %s" % path)
        return
    var text := file.get_as_text()
    file.close()
    var parsed := JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("RunModifierSystem: %s did not parse as a dictionary" % path)
        return
    var modifier_list := parsed.get("modifiers", [])
    if typeof(modifier_list) == TYPE_ARRAY:
        for entry in modifier_list:
            if typeof(entry) == TYPE_DICTIONARY:
                _register_modifier(entry)
    var themes_list := parsed.get("themes", [])
    if typeof(themes_list) == TYPE_ARRAY:
        for entry in themes_list:
            if typeof(entry) == TYPE_DICTIONARY:
                _register_theme(entry)

func _register_modifier(data: Dictionary) -> void:
    var id := StringName(data.get("id", ""))
    if id.is_empty():
        return
    if _modifiers_by_id.has(id):
        push_warning("RunModifierSystem: Duplicate modifier id %s" % id)
        return
    var normalized := data.duplicate(true)
    normalized["id"] = id
    normalized["type"] = String(normalized.get("type", "boon"))
    normalized["weight"] = float(normalized.get("weight", 1.0))
    normalized["profile"] = _normalize_profile(normalized.get("profile", {}))
    var tags: Array[StringName] = []
    var class_tags := normalized.get("class_tags", [])
    if typeof(class_tags) == TYPE_ARRAY:
        for tag in class_tags:
            var name := StringName(tag)
            if name in tags:
                continue
            tags.append(name)
    normalized["class_tags"] = tags
    _modifiers_by_id[id] = normalized
    var target := normalized.get("type", "boon")
    var index := _class_boons_by_tag if target == "boon" else _class_banes_by_tag
    for tag in tags:
        var existing: Array[StringName] = index.get(tag, [])
        if id not in existing:
            existing.append(id)
        index[tag] = existing

func _register_theme(data: Dictionary) -> void:
    var id := StringName(data.get("id", ""))
    if id.is_empty():
        return
    var normalized := data.duplicate(true)
    normalized["id"] = id
    normalized["weight"] = float(normalized.get("weight", 1.0))
    normalized["profile"] = _normalize_profile(normalized.get("profile", {}))
    var tags: Array[StringName] = []
    var raw_tags := normalized.get("tags", [])
    if typeof(raw_tags) == TYPE_ARRAY:
        for tag in raw_tags:
            var name := StringName(tag)
            if name in tags:
                continue
            tags.append(name)
    normalized["tags"] = tags
    normalized["boon_pool"] = _normalize_pool(normalized.get("boon_pool", []))
    normalized["bane_pool"] = _normalize_pool(normalized.get("bane_pool", []))
    _themes.append(normalized)

func _normalize_pool(raw: Variant) -> Array[StringName]:
    var result: Array[StringName] = []
    if typeof(raw) != TYPE_ARRAY:
        return result
    for id in raw:
        var name := StringName(id)
        if name.is_empty():
            continue
        if not _modifiers_by_id.has(name):
            push_warning("RunModifierSystem: Theme references unknown modifier %s" % name)
            continue
        if name in result:
            continue
        result.append(name)
    return result

func _resolve_class_identity(class_data: Dictionary, particle_class: ParticleClassDefinition) -> void:
    _current_class_tags.clear()
    _current_class_id = &""
    if particle_class:
        _current_class_id = particle_class.id
        for tag in particle_class.get_class_tags():
            if tag not in _current_class_tags:
                _current_class_tags.append(tag)
    var id_string := String(class_data.get("id", ""))
    if not id_string.is_empty():
        if id_string.begins_with("quark_"):
            var tag := StringName("quark")
            if tag not in _current_class_tags:
                _current_class_tags.append(tag)
        elif id_string.begins_with("lepton_"):
            var tag := StringName("lepton")
            if tag not in _current_class_tags:
                _current_class_tags.append(tag)
        elif id_string.begins_with("boson_"):
            var tag := StringName("boson")
            if tag not in _current_class_tags:
                _current_class_tags.append(tag)
        elif id_string.begins_with("element_"):
            var tag := StringName("element")
            if tag not in _current_class_tags:
                _current_class_tags.append(tag)
    var base_stats := class_data.get("base_stats", {})
    if typeof(base_stats) == TYPE_DICTIONARY:
        if base_stats.has("atomic_mass"):
            var mass := float(base_stats.get("atomic_mass", 0.0))
            if mass >= 150.0:
                var tag := StringName("heavy_element")
                if tag not in _current_class_tags:
                    _current_class_tags.append(tag)
        if base_stats.has("mass_mev"):
            var mev := float(base_stats.get("mass_mev", 0.0))
            if mev >= 1000.0:
                var tag := StringName("massive_particle")
                if tag not in _current_class_tags:
                    _current_class_tags.append(tag)
    var baseline_tag := StringName("run_participant")
    if baseline_tag not in _current_class_tags:
        _current_class_tags.append(baseline_tag)

func _roll_theme() -> Dictionary:
    if _themes.is_empty():
        return {}
    var weights: Array[float] = []
    var total := 0.0
    for theme in _themes:
        var weight := float(theme.get("weight", 1.0))
        if weight <= 0.0:
            continue
        weights.append(weight)
        total += weight
    if total <= 0.0:
        return {}
    var roll := _rng.randf() * total
    for i in range(_themes.size()):
        var theme := _themes[i]
        var weight := float(theme.get("weight", 1.0))
        if weight <= 0.0:
            continue
        roll -= weight
        if roll <= 0.0:
            return theme
    return _themes.back()

func _activate_theme(theme: Dictionary) -> void:
    _deactivate_theme()
    _active_theme = theme.duplicate(true)
    var theme_id: StringName = _active_theme.get("id", StringName())
    var profile: Dictionary = _active_theme.get("profile", {})
    var profile_source: ModifierProfileSource = null
    if _player and not profile.is_empty():
        profile_source = ModifierProfileSource.new(theme_id)
        _player.apply_stat_profile(profile_source, profile)
    var callback := _instantiate_callback(String(_active_theme.get("callback", "")))
    var record := {
        "profile_source": profile_source,
        "callback": callback,
        "data": _active_theme,
        "is_theme": true,
    }
    _active_records[theme_id] = record
    if callback:
        callback.on_applied(self, _player, _active_theme, {"role": "theme"})
    emit_signal("theme_changed", theme_id, _active_theme)
    _record_stage_combo()

func _deactivate_theme() -> void:
    if _active_theme.is_empty():
        return
    var theme_id: StringName = _active_theme.get("id", StringName())
    _remove_modifier(theme_id)
    _active_theme = {}

func _roll_stage_modifiers(stage_index: int, context: Dictionary) -> Array[StringName]:
    var applied: Array[StringName] = []
    var boon_candidates := _gather_candidates(true)
    var bane_candidates := _gather_candidates(false)
    var boon_id := _choose_modifier_from_candidates(boon_candidates)
    if not boon_id.is_empty():
        if _apply_modifier(boon_id, stage_index, context.merged({"role": "boon"})):
            applied.append(boon_id)
    var bane_id := _choose_modifier_from_candidates(bane_candidates)
    if not bane_id.is_empty():
        if _apply_modifier(bane_id, stage_index, context.merged({"role": "bane"})):
            applied.append(bane_id)
    return applied

func _gather_candidates(is_boon: bool) -> Array[StringName]:
    var result: Array[StringName] = []
    if not _active_theme.is_empty():
        var pool: Array[StringName] = _active_theme.get("boon_pool" if is_boon else "bane_pool", [])
        for id in pool:
            if id not in result:
                result.append(id)
    var index := _class_boons_by_tag if is_boon else _class_banes_by_tag
    for tag in _current_class_tags:
        var ids: Array[StringName] = index.get(tag, [])
        for id in ids:
            if id not in result:
                result.append(id)
    return result

func _choose_modifier_from_candidates(candidates: Array[StringName]) -> StringName:
    if candidates.is_empty():
        return StringName()
    var weights: Array[float] = []
    var total := 0.0
    for id in candidates:
        var data: Dictionary = _modifiers_by_id.get(id, {})
        var weight := float(data.get("weight", 1.0))
        if _unlock_manager and not _current_class_id.is_empty():
            var theme_id := StringName()
            if not _active_theme.is_empty():
                theme_id = _active_theme.get("id", StringName())
            if not _unlock_manager.has_discovered_modifier_combo(_current_class_id, theme_id, [id]):
                weight *= 1.5
        weights.append(weight)
        total += weight
    if total <= 0.0:
        return candidates[_rng.randi_range(0, candidates.size() - 1)]
    var roll := _rng.randf() * total
    for index in range(candidates.size()):
        roll -= weights[index]
        if roll <= 0.0:
            return candidates[index]
    return candidates.back()

func _apply_modifier(modifier_id: StringName, stage_index: int, context: Dictionary) -> bool:
    if modifier_id.is_empty():
        return false
    if not _modifiers_by_id.has(modifier_id):
        return false
    _remove_modifier(modifier_id)
    var data: Dictionary = _modifiers_by_id[modifier_id]
    var profile: Dictionary = data.get("profile", {})
    var profile_source: ModifierProfileSource = null
    if _player and not profile.is_empty():
        profile_source = ModifierProfileSource.new(modifier_id)
        _player.apply_stat_profile(profile_source, profile)
    var callback := _instantiate_callback(String(data.get("callback", "")))
    var record := {
        "profile_source": profile_source,
        "callback": callback,
        "data": data,
        "stage_index": stage_index,
    }
    _active_records[modifier_id] = record
    if callback:
        callback.on_applied(self, _player, data, context.merged({"stage": stage_index}))
    emit_signal("modifier_applied", modifier_id, data)
    return true

func _remove_modifier(modifier_id: StringName) -> void:
    if modifier_id.is_empty():
        return
    if not _active_records.has(modifier_id):
        return
    var record: Dictionary = _active_records[modifier_id]
    var profile_source: ModifierProfileSource = record.get("profile_source")
    if _player and profile_source:
        _player.remove_stat_profile(profile_source)
    var callback: ModifierCallback = record.get("callback")
    if callback:
        callback.on_removed(self, _player, record.get("data", {}), {})
    _active_records.erase(modifier_id)
    emit_signal("modifier_removed", modifier_id)

func _clear_stage_modifiers() -> void:
    for id in _active_stage_modifiers:
        _remove_modifier(id)
    _active_stage_modifiers.clear()

func _clear_all_modifiers() -> void:
    _clear_stage_modifiers()
    _deactivate_theme()
    _active_records.clear()
    _current_stage_index = -1

func _instantiate_callback(path: String) -> ModifierCallback:
    if path.is_empty():
        return null
    var resource := load(path)
    if resource == null:
        push_warning("RunModifierSystem: Failed to load callback %s" % path)
        return null
    if resource is Script:
        var instance := resource.new()
        if instance is ModifierCallback:
            return instance
        push_warning("RunModifierSystem: Callback %s does not extend RunModifierCallback" % path)
        return null
    if resource is ModifierCallback:
        return resource.duplicate()
    push_warning("RunModifierSystem: Callback %s is not compatible" % path)
    return null

func _call_stage_callbacks(stage_index: int, context: Dictionary) -> void:
    for id in _active_records.keys():
        var record: Dictionary = _active_records[id]
        var callback: ModifierCallback = record.get("callback")
        if callback:
            callback.on_stage_advance(self, _player, record.get("data", {}), stage_index, context)

func _record_stage_combo() -> void:
    if _unlock_manager == null:
        return
    if _current_class_id.is_empty():
        return
    var theme_id := StringName()
    if not _active_theme.is_empty():
        theme_id = _active_theme.get("id", StringName())
    var ids: Array[StringName] = []
    for id in _active_stage_modifiers:
        ids.append(id)
    _unlock_manager.record_modifier_combo(_current_class_id, theme_id, ids)

func _normalize_profile(raw: Variant) -> Dictionary:
    var result := {
        "bonuses": {},
        "multipliers": {},
        "keywords": [],
    }
    if typeof(raw) != TYPE_DICTIONARY:
        return result
    var bonuses := raw.get("bonuses", {})
    if typeof(bonuses) == TYPE_DICTIONARY:
        var bonus_map := {}
        for key in bonuses.keys():
            bonus_map[key] = float(bonuses[key])
        result["bonuses"] = bonus_map
    var multipliers := raw.get("multipliers", {})
    if typeof(multipliers) == TYPE_DICTIONARY:
        var mult_map := {}
        for key in multipliers.keys():
            mult_map[key] = float(multipliers[key])
        result["multipliers"] = mult_map
    var keywords := raw.get("keywords", [])
    if typeof(keywords) == TYPE_ARRAY:
        var list := []
        for keyword in keywords:
            var name := StringName(keyword)
            if name in list:
                continue
            list.append(name)
        result["keywords"] = list
    return result
