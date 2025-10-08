extends Node
class_name StatusManager

signal status_applied(status_name: StringName, info: Dictionary)
signal status_refreshed(status_name: StringName, info: Dictionary)
signal status_removed(status_name: StringName, info: Dictionary)
signal self_damage_triggered(payload: Dictionary)

@export var host: Node = null
@export var immunity_flags: Dictionary = {}

@export var instability_factor: float = 0.0:
    set(value):
        set_instability_factor(value)
    get:
        return get_instability_factor()

var _statuses: Dictionary = {}
var _instability_factor: float = 0.0

func _ready() -> void:
    set_process(true)

func _process(delta: float) -> void:
    tick(delta)

func set_instability_factor(value: float) -> void:
    _instability_factor = max(value, 0.0)

func get_instability_factor() -> float:
    return _instability_factor

func tick(delta: float) -> void:
    if _statuses.is_empty():
        return
    var expired: Array[StringName] = []
    for status_name in _statuses.keys():
        var info: Dictionary = _statuses[status_name]
        info["remaining"] = max(info.get("remaining", 0.0) - delta, 0.0)
        _handle_self_damage(status_name, info, delta)
        _statuses[status_name] = info
        if info.get("remaining", 0.0) <= 0.0:
            expired.append(status_name)
    for status_name in expired:
        var removed_info: Dictionary = _statuses[status_name]
        _statuses.erase(status_name)
        emit_signal("status_removed", status_name, removed_info.duplicate(true))

func apply_status(status_name: StringName, duration: float, data: Dictionary = {}, source = null) -> Dictionary:
    if duration <= 0.0:
        return {"success": false, "reason": "invalid_duration"}
    var status_data := data.duplicate(true)
    if _is_immune(status_data):
        return {
            "success": false,
            "immune": true,
            "status": status_name,
            "log": "%s is immune to %s." % [str(host), str(status_name)],
        }
    var info: Dictionary = _statuses.get(status_name, {})
    if info.is_empty():
        info = {
            "name": status_name,
            "duration": duration,
            "remaining": duration,
            "source": source,
            "data": status_data,
            "stacks": 1,
        }
        _statuses[status_name] = info
        emit_signal("status_applied", status_name, info.duplicate(true))
        return {
            "success": true,
            "applied": true,
            "status": info.duplicate(true),
        }
    info["source"] = source
    var refresh_mode := status_data.get("refresh_mode", "max")
    if refresh_mode == "add":
        info["remaining"] = info.get("remaining", duration) + duration
    else:
        info["remaining"] = max(info.get("remaining", duration), duration)
    if status_data.get("stackable", false):
        var max_stacks := int(status_data.get("max_stacks", 5))
        info["stacks"] = clamp(info.get("stacks", 1) + 1, 1, max_stacks)
    info["data"] = _merge_dict(info.get("data", {}), status_data)
    _statuses[status_name] = info
    emit_signal("status_refreshed", status_name, info.duplicate(true))
    return {
        "success": true,
        "refreshed": true,
        "status": info.duplicate(true),
    }

func remove_status(status_name: StringName) -> void:
    if not _statuses.has(status_name):
        return
    var info: Dictionary = _statuses[status_name]
    _statuses.erase(status_name)
    emit_signal("status_removed", status_name, info.duplicate(true))

func clear_all_statuses() -> void:
    if _statuses.is_empty():
        return
    for status_name in _statuses.keys():
        emit_signal("status_removed", status_name, _statuses[status_name].duplicate(true))
    _statuses.clear()

func has_status(status_name: StringName) -> bool:
    return _statuses.has(status_name)

func get_status(status_name: StringName) -> Dictionary:
    var info: Dictionary = _statuses.get(status_name, {})
    return info.duplicate(true) if not info.is_empty() else {}

func set_immunity(tag: StringName, enabled: bool) -> void:
    immunity_flags[tag] = enabled

func clear_immunities() -> void:
    immunity_flags.clear()

func is_immune_to(tag: StringName) -> bool:
    return bool(immunity_flags.get(tag, false))

func _is_immune(data: Dictionary) -> bool:
    var tags: Array = data.get("tags", [])
    for tag in tags:
        if is_immune_to(tag):
            return true
    return false

func _handle_self_damage(status_name: StringName, info: Dictionary, delta: float) -> void:
    var data: Dictionary = info.get("data", {})
    var self_damage: Dictionary = data.get("self_damage", {})
    if self_damage.is_empty():
        return
    var rate := float(self_damage.get("per_second", 0.0))
    if rate <= 0.0:
        return
    var scale := 1.0
    if self_damage.get("scales_with_instability", true):
        scale += _instability_factor
    var amount := rate * delta * scale
    if amount <= 0.0:
        return
    var payload := {
        "status": status_name,
        "amount": amount,
        "type": self_damage.get("type", StringName("")),
        "source": info.get("source"),
    }
    emit_signal("self_damage_triggered", payload)
    if host and host.has_method("apply_self_damage"):
        host.apply_self_damage(payload)

func _merge_dict(base: Dictionary, extra: Dictionary) -> Dictionary:
    var result := base.duplicate(true)
    for key in extra.keys():
        result[key] = extra[key]
    return result
