extends Node
class_name BoonManager

const DATA_DIR := "res://data/boons"

signal boon_options_ready(source: StringName, options: Array)
signal boon_applied(boon_id: StringName, source: StringName, details: Dictionary)

class BoonProfileSource:
    extends RefCounted

    var boon_id: StringName

    func _init(id: StringName) -> void:
        boon_id = id

var _rng := RandomNumberGenerator.new()
var _boons_by_id: Dictionary = {}
var _boon_ids: Array[StringName] = []
var _active_boons: Dictionary = {}
var _player: PlayerAvatar
var _active_theme_tags: Array[StringName] = []

func _ready() -> void:
    _rng.randomize()
    load_data()

func load_data() -> void:
    _boons_by_id.clear()
    _boon_ids.clear()
    var dir := DirAccess.open(DATA_DIR)
    if dir == null:
        push_error("BoonManager: Unable to open data directory %s" % DATA_DIR)
        return
    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if not dir.current_is_dir() and file_name.to_lower().ends_with(".json"):
            _load_boons_from_file("%s/%s" % [DATA_DIR, file_name])
        file_name = dir.get_next()
    dir.list_dir_end()

func set_player(player: PlayerAvatar) -> void:
    _player = player

func set_active_theme_tags(tags: Array) -> void:
    _active_theme_tags.clear()
    for tag in tags:
        var theme := StringName(tag)
        if theme in _active_theme_tags:
            continue
        _active_theme_tags.append(theme)

func add_active_theme_tag(tag: StringName) -> void:
    tag = StringName(tag)
    if tag in _active_theme_tags:
        return
    _active_theme_tags.append(tag)

func remove_active_theme_tag(tag: StringName) -> void:
    tag = StringName(tag)
    _active_theme_tags.erase(tag)

func clear_active_theme_tags() -> void:
    _active_theme_tags.clear()

func on_run_started(_class_data: Dictionary, _particle_class: ParticleClassDefinition) -> void:
    clear_all_boons()
    clear_active_theme_tags()

func clear_all_boons() -> void:
    var ids := _active_boons.keys()
    for id in ids:
        remove_boon(StringName(id))

func remove_boon(boon_id: StringName) -> void:
    boon_id = StringName(boon_id)
    if not _active_boons.has(boon_id):
        return
    var record: Dictionary = _active_boons[boon_id]
    if _player:
        var profile_source = record.get("profile_source")
        if profile_source:
            _player.remove_stat_profile(profile_source)
        var ability_source = record.get("ability_source")
        if ability_source:
            _player.remove_ability_override(ability_source)
    _active_boons.erase(boon_id)

func roll_enemy_drop(enemy_context: Dictionary = {}) -> void:
    var context := _build_context(&"enemy_drop", enemy_context)
    var count := max(1, int(enemy_context.get("count", 2)))
    _emit_boon_options(&"enemy_drop", context, count)

func roll_event_room(event_context: Dictionary = {}) -> void:
    var context := _build_context(&"event_room", event_context)
    var count := max(1, int(event_context.get("count", 3)))
    _emit_boon_options(&"event_room", context, count)

func roll_shop_inventory(shop_context: Dictionary = {}) -> void:
    var context := _build_context(&"shop", shop_context)
    var count := max(1, int(shop_context.get("count", 3)))
    _emit_boon_options(&"shop", context, count)

func apply_boon(boon_id: StringName, source: StringName = &"manual", context: Dictionary = {}) -> Dictionary:
    boon_id = StringName(boon_id)
    if not _boons_by_id.has(boon_id):
        push_warning("BoonManager: Unknown boon %s" % boon_id)
        return {}
    if _player == null:
        push_warning("BoonManager: No player bound, cannot apply boon %s" % boon_id)
        return {}
    var boon: Dictionary = _boons_by_id[boon_id]
    if _active_boons.has(boon_id) and not bool(boon.get("stackable", false)):
        remove_boon(boon_id)
    var effects: Dictionary = boon.get("effects", {})
    var profile_source: BoonProfileSource = null
    var ability_source: BoonProfileSource = null
    var result := {
        "id": boon_id,
        "applied_profile": false,
        "ability_override": false,
    }
    if not effects.is_empty():
        var profile: Dictionary = effects.get("profile", {})
        var duration := float(effects.get("profile_duration", 0.0))
        if not profile.is_empty():
            profile_source = BoonProfileSource.new(boon_id)
            if duration > 0.0:
                _player.apply_temporary_profile(profile_source, profile, duration)
            else:
                _player.apply_stat_profile(profile_source, profile)
            result["applied_profile"] = true
            result["profile_duration"] = duration
        var ability_swap: Dictionary = effects.get("ability_swap", {})
        if not ability_swap.is_empty():
            var slot := StringName(ability_swap.get("slot", ""))
            var ability_id := StringName(ability_swap.get("ability_id", ""))
            var ability_duration := float(ability_swap.get("duration", 0.0))
            if not slot.is_empty() and not ability_id.is_empty():
                ability_source = BoonProfileSource.new(boon_id)
                if _player.override_ability(slot, ability_id, ability_duration, ability_source):
                    result["ability_override"] = true
                    result["ability_slot"] = slot
                    result["ability_id"] = ability_id
                    result["ability_duration"] = ability_duration
                else:
                    ability_source = null
    if profile_source == null and ability_source == null:
        _active_boons[boon_id] = {"context": context}
    else:
        _active_boons[boon_id] = {
            "profile_source": profile_source,
            "ability_source": ability_source,
            "context": context,
        }
    emit_signal("boon_applied", boon_id, source, result)
    return result

func _emit_boon_options(source: StringName, context: Dictionary, count: int) -> void:
    var candidates := _collect_candidates(context)
    if candidates.is_empty():
        return
    var selected := _pick_random_boons(candidates, count)
    if selected.is_empty():
        return
    var options: Array = []
    for boon in selected:
        options.append(_public_boon_data(boon))
    emit_signal("boon_options_ready", source, options)

func _collect_candidates(context: Dictionary) -> Array:
    var results: Array = []
    for id in _boon_ids:
        var boon: Dictionary = _boons_by_id[id]
        if not bool(boon.get("stackable", false)) and _active_boons.has(id):
            continue
        if _boon_meets_requirements(boon, context):
            results.append(boon)
    return results

func _pick_random_boons(candidates: Array, count: int) -> Array:
    var picks: Array = []
    var pool: Array = candidates.duplicate()
    while picks.size() < count and pool.size() > 0:
        var total_weight := 0.0
        for entry in pool:
            total_weight += max(float(entry.get("weight", 1.0)), 0.0)
        if total_weight <= 0.0:
            total_weight = float(pool.size())
        var roll := _rng.randf_range(0.0, total_weight)
        var chosen_index := 0
        for i in range(pool.size()):
            roll -= max(float(pool[i].get("weight", 1.0)), 0.0)
            if roll <= 0.0:
                chosen_index = i
                break
        var chosen := pool[chosen_index]
        picks.append(chosen)
        pool.remove_at(chosen_index)
    return picks

func _public_boon_data(boon: Dictionary) -> Dictionary:
    var data := {
        "id": boon["id"],
        "display_name": boon.get("display_name", ""),
        "description": boon.get("description", ""),
        "prerequisites": boon.get("prerequisites", []).duplicate(),
        "themes": boon.get("themes", []).duplicate(),
        "effects": boon.get("effects", {}).duplicate(true),
    }
    return data

func _boon_meets_requirements(boon: Dictionary, context: Dictionary) -> bool:
    var requirements: Array = boon.get("prerequisites", [])
    for requirement in requirements:
        var req := String(requirement)
        match req:
            "requires_charge_negative":
                if float(context.get("charge", 0.0)) >= -0.0001:
                    return false
            "requires_charge_positive":
                if float(context.get("charge", 0.0)) <= 0.0001:
                    return false
            "requires_charge_neutral":
                if abs(float(context.get("charge", 0.0))) > 0.1:
                    return false
            "requires_low_stability":
                if float(context.get("stability", 1.0)) >= 0.5:
                    return false
            "source_enemy":
                if context.get("source") != &"enemy_drop":
                    return false
            "source_event":
                if context.get("source") != &"event_room":
                    return false
            "source_shop":
                if context.get("source") != &"shop":
                    return false
            _:
                if req.begins_with("theme_"):
                    if not _has_theme(StringName(req), context):
                        return false
                elif req.begins_with("requires_tag_"):
                    var tag := StringName(req.substr("requires_tag_".length()))
                    if not _array_has(context.get("class_tags", []), tag):
                        return false
                elif req.begins_with("requires_keyword_"):
                    var keyword := StringName(req.substr("requires_keyword_".length()))
                    if not _array_has(context.get("keywords", []), keyword):
                        return false
    return true

func _has_theme(tag: StringName, context: Dictionary) -> bool:
    tag = StringName(tag)
    var themes: Array = context.get("theme_tags", [])
    if _array_has(themes, tag):
        return true
    return false

func _array_has(array: Array, value) -> bool:
    var target = value
    if target is String:
        target = StringName(target)
    for element in array:
        if element is String:
            if StringName(element) == target:
                return true
        elif element == target:
            return true
    return false

func _build_context(source: StringName, extra: Dictionary) -> Dictionary:
    var context := _build_player_state()
    context["source"] = source
    context["theme_tags"] = _resolve_theme_tags(extra.get("theme_tags", _active_theme_tags))
    if extra.has("enemy_tags"):
        context["enemy_tags"] = _resolve_string_array(extra.get("enemy_tags"))
    if extra.has("event_tags"):
        context["event_tags"] = _resolve_string_array(extra.get("event_tags"))
    if extra.has("shop_tags"):
        context["shop_tags"] = _resolve_string_array(extra.get("shop_tags"))
    return context

func _build_player_state() -> Dictionary:
    var state := {
        "charge": 0.0,
        "stability": 1.0,
        "class_tags": [],
        "keywords": [],
        "stats": {},
    }
    if _player:
        state["charge"] = _player.charge
        state["stability"] = _player.stability
        state["class_tags"] = _player.get_class_tags()
        state["keywords"] = _player.current_keywords.duplicate()
        state["stats"] = _player.current_stats.duplicate(true)
    return state

func _resolve_theme_tags(value) -> Array[StringName]:
    var tags: Array[StringName] = []
    if value is Array:
        for entry in value:
            tags.append(StringName(entry))
    elif value is String or value is StringName:
        tags.append(StringName(value))
    if tags.is_empty():
        for tag in _active_theme_tags:
            tags.append(tag)
    return tags

func _resolve_string_array(value) -> Array[StringName]:
    var tags: Array[StringName] = []
    if value is Array:
        for entry in value:
            tags.append(StringName(entry))
    elif value is String or value is StringName:
        tags.append(StringName(value))
    return tags

func _load_boons_from_file(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_warning("BoonManager: Unable to read %s" % path)
        return
    var text := file.get_as_text()
    file.close()
    var parsed := JSON.parse_string(text)
    match typeof(parsed):
        TYPE_DICTIONARY:
            _register_boon(parsed, path)
        TYPE_ARRAY:
            for entry in parsed:
                if entry is Dictionary:
                    _register_boon(entry, path)
                else:
                    push_warning("BoonManager: Ignoring non-dictionary entry in %s" % path)
        _:
            push_warning("BoonManager: Unexpected data in %s" % path)

func _register_boon(entry: Dictionary, source: String) -> void:
    var id := String(entry.get("id", ""))
    if id.is_empty():
        push_warning("BoonManager: Entry in %s missing id" % source)
        return
    var key := StringName(id)
    var stored := entry.duplicate(true)
    stored["id"] = key
    stored["prerequisites"] = _to_string_array(entry.get("prerequisites", []))
    stored["themes"] = _to_string_array(entry.get("themes", []))
    stored["weight"] = float(entry.get("weight", 1.0))
    stored["effects"] = entry.get("effects", {}).duplicate(true)
    stored["stackable"] = bool(entry.get("stackable", false))
    stored["source_file"] = source
    _boons_by_id[key] = stored
    if key not in _boon_ids:
        _boon_ids.append(key)

func _to_string_array(value) -> Array:
    var result: Array = []
    if value is Array:
        for entry in value:
            result.append(String(entry))
    elif value is String or value is StringName:
        result.append(String(value))
    return result
