extends Node
class_name UnlockManager

const STORAGE_PATH := "user://progression_state.json"

var _runs_completed: int = 0
var _manual_unlocks: Dictionary = {}

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

func _save_state() -> void:
    var file := FileAccess.open(STORAGE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("UnlockManager: Failed to persist progression state.")
        return
    var payload := {
        "runs_completed": _runs_completed,
        "manual_unlocks": _manual_unlocks,
    }
    file.store_string(JSON.stringify(payload))
    file.close()
