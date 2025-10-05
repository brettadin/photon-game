extends Node
class_name UnlockManager

const STORAGE_PATH := "user://progression_state.json"

var _runs_completed: int = 0
var _manual_unlocks: Dictionary = {}
var _codex_entries: Dictionary = {}
var _discovered_modifier_combos: Dictionary = {}

func _init() -> void:
    _load_state()

func record_run_completed() -> void:
    _runs_completed += 1
    _save_state()

func unlock_class(id: StringName) -> void:
    id = StringName(id)
    if _manual_unlocks.get(id, false):
        return
    _manual_unlocks[id] = true
    _save_state()

func unlock_codex_entry(id: StringName) -> void:
    id = StringName(id)
    if id.is_empty():
        return
    if _codex_entries.get(id, false):
        return
    _codex_entries[id] = true
    _save_state()

func unlock_codex_entries(ids: Array) -> void:
    for id in ids:
        unlock_codex_entry(StringName(id))

func is_class_unlocked(class_data: Dictionary) -> bool:
    var id := StringName(class_data.get("id", ""))
    if id.is_empty():
        return false
    if _manual_unlocks.get(id, false):
        return true
    var requirement := get_unlock_requirement(class_data)
    if requirement.is_empty():
        return true
    match requirement.get("type", ""):
        "runs_completed":
            return _runs_completed >= int(requirement.get("runs", 0))
        _:
            return true

func get_unlock_requirement(class_data: Dictionary) -> Dictionary:
    var stats: Dictionary = class_data.get("base_stats", {})
    if stats.is_empty():
        return {}
    if stats.has("mass_mev"):
        return _get_mass_requirement(float(stats.get("mass_mev", 0.0)))
    if stats.has("atomic_mass"):
        return _get_mass_requirement(float(stats.get("atomic_mass", 0.0)))
    if stats.has("reactivity"):
        var value := float(stats.get("reactivity", 0.0))
        if value >= 0.95:
            return {
                "type": "runs_completed",
                "runs": 3,
                "description": "Complete 3 runs to stabilise highly reactive elements.",
            }
    return {}

func describe_requirement(requirement: Dictionary) -> String:
    if requirement.is_empty():
        return ""
    match requirement.get("type", ""):
        "runs_completed":
            var runs := int(requirement.get("runs", 0))
            if requirement.has("description") and not String(requirement["description"]).is_empty():
                return String(requirement["description"])
            if runs <= 1:
                return "Complete 1 run to unlock."
            return "Complete %d runs to unlock." % runs
        _:
            return String(requirement.get("description", ""))

func get_runs_completed() -> int:
    return _runs_completed

func is_codex_entry_unlocked(id: StringName) -> bool:
    id = StringName(id)
    if id.is_empty():
        return false
    return _codex_entries.get(id, false)

func get_unlocked_codex_entries() -> Array:
    var ids := []
    for key in _codex_entries.keys():
        if _codex_entries[key]:
            ids.append(String(key))
    return ids

func record_modifier_combo(class_id: StringName, theme_id: StringName, modifier_ids: Array) -> void:
    class_id = StringName(class_id)
    theme_id = _normalise_theme_id(theme_id)
    if class_id.is_empty():
        return
    var normalized_ids := _normalise_modifier_ids(modifier_ids)
    var class_map: Dictionary = _discovered_modifier_combos.get(class_id, {})
    var theme_map: Dictionary = class_map.get(theme_id, {})
    var key := _combo_key(normalized_ids)
    if theme_map.has(key):
        return
    theme_map[key] = normalized_ids
    class_map[theme_id] = theme_map
    _discovered_modifier_combos[class_id] = class_map
    _save_state()

func has_discovered_modifier_combo(class_id: StringName, theme_id: StringName, modifier_ids: Array) -> bool:
    class_id = StringName(class_id)
    theme_id = _normalise_theme_id(theme_id)
    if class_id.is_empty():
        return false
    var normalized_ids := _normalise_modifier_ids(modifier_ids)
    var class_map: Dictionary = _discovered_modifier_combos.get(class_id, {})
    var theme_map: Dictionary = class_map.get(theme_id, {})
    var key := _combo_key(normalized_ids)
    return theme_map.has(key)

func get_discovered_modifier_combos(class_id: StringName) -> Dictionary:
    class_id = StringName(class_id)
    if class_id.is_empty():
        return {}
    var class_map: Dictionary = _discovered_modifier_combos.get(class_id, {})
    var result := {}
    for theme_id in class_map.keys():
        var theme_map: Dictionary = class_map[theme_id]
        var combos := []
        for key in theme_map.keys():
            var ids: Array = theme_map[key]
            combos.append(ids.duplicate())
        result[String(theme_id)] = combos
    return result

func _get_mass_requirement(mass: float) -> Dictionary:
    if mass >= 100000.0:
        return {
            "type": "runs_completed",
            "runs": 5,
            "description": "Complete 5 runs to stabilise ultra-heavy generations.",
        }
    if mass >= 1000.0:
        return {
            "type": "runs_completed",
            "runs": 3,
            "description": "Complete 3 runs to unlock high-mass variants.",
        }
    if mass >= 50.0:
        return {
            "type": "runs_completed",
            "runs": 1,
            "description": "Complete a run to access heavier generations.",
        }
    return {}

func _load_state() -> void:
    if not FileAccess.file_exists(STORAGE_PATH):
        return
    var file := FileAccess.open(STORAGE_PATH, FileAccess.READ)
    if file == null:
        return
    var text := file.get_as_text()
    file.close()
    var data := JSON.parse_string(text)
    if typeof(data) != TYPE_DICTIONARY:
        return
    _runs_completed = int(data.get("runs_completed", 0))
    var manual := data.get("manual_unlocks", {})
    if typeof(manual) == TYPE_DICTIONARY:
        _manual_unlocks.clear()
        for key in manual.keys():
            if manual[key]:
                _manual_unlocks[StringName(key)] = true
    var codex_data := data.get("codex_entries", [])
    if typeof(codex_data) == TYPE_ARRAY:
        _codex_entries.clear()
        for id in codex_data:
            _codex_entries[StringName(id)] = true
    var modifier_data := data.get("modifier_combos", {})
    if typeof(modifier_data) == TYPE_DICTIONARY:
        _discovered_modifier_combos.clear()
        for class_key in modifier_data.keys():
            var theme_source := modifier_data[class_key]
            if typeof(theme_source) != TYPE_DICTIONARY:
                continue
            var class_map := {}
            for theme_key in theme_source.keys():
                var combos_array := theme_source[theme_key]
                if typeof(combos_array) != TYPE_ARRAY:
                    continue
                var theme_map := {}
                for entry in combos_array:
                    var ids := _normalise_modifier_ids(entry if typeof(entry) == TYPE_ARRAY else [])
                    var combo_key := _combo_key(ids)
                    theme_map[combo_key] = ids
                class_map[_normalise_theme_id(theme_key)] = theme_map
            _discovered_modifier_combos[StringName(class_key)] = class_map

func _save_state() -> void:
    var file := FileAccess.open(STORAGE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("UnlockManager: Failed to persist progression state.")
        return
    var codex_array := []
    for key in _codex_entries.keys():
        if _codex_entries[key]:
            codex_array.append(String(key))
    var modifier_payload := {}
    for class_id in _discovered_modifier_combos.keys():
        var class_map: Dictionary = _discovered_modifier_combos[class_id]
        var theme_payload := {}
        for theme_id in class_map.keys():
            var theme_map: Dictionary = class_map[theme_id]
            var combos := []
            for combo_key in theme_map.keys():
                var ids: Array = theme_map[combo_key]
                combos.append(ids.duplicate())
            theme_payload[String(theme_id)] = combos
        modifier_payload[String(class_id)] = theme_payload
    var payload := {
        "runs_completed": _runs_completed,
        "manual_unlocks": _manual_unlocks,
        "codex_entries": codex_array,
        "modifier_combos": modifier_payload,
    }
    file.store_string(JSON.stringify(payload))
    file.close()

func _combo_key(ids: Array) -> String:
    if ids.is_empty():
        return "__none__"
    return "|".join(ids)

func _normalise_modifier_ids(input_ids: Variant) -> Array:
    var values: Array = []
    if typeof(input_ids) == TYPE_ARRAY:
        for id in input_ids:
            var value := String(id)
            if value.is_empty():
                continue
            values.append(value)
    values.sort()
    return values

func _normalise_theme_id(theme_id: Variant) -> StringName:
    var value := String(theme_id)
    if value.is_empty():
        return StringName("__none__")
    return StringName(value)
