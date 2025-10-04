extends Resource
class_name Ability

## Base ability resource that handles activation cooldowns, resource costs,
## and animation hooks. Concrete abilities should inherit from this class
## and override [_execute_activation] to provide their gameplay effect.

signal cooldown_started(duration: float)
signal cooldown_completed()

@export var ability_name: String = ""
@export_multiline var description: String = ""
@export var cooldown: float = 0.0
@export var resource_costs: Dictionary = {}
@export var animation_state: StringName = &""
@export var animation_speed: float = 1.0
@export var animation_blend_time: float = 0.1

var slot: StringName = &""
var _cooldown_ready_time: float = 0.0

func on_equip(_user) -> void:
    pass

func on_unequip(_user) -> void:
    pass

func can_activate(user, context: Dictionary = {}) -> Dictionary:
    if is_on_cooldown():
        var remaining := get_cooldown_remaining()
        return {
            "allowed": false,
            "log": "%s is recharging (%0.2fs remaining)." % [ability_name, remaining],
            "cooldown_remaining": remaining,
        }
    var cost_check := _can_pay_cost(user)
    if not cost_check.get("ok", true):
        var missing: Dictionary = cost_check.get("missing", {})
        var log := cost_check.get("log", "")
        if log == "" and not missing.is_empty():
            log = "%s requires %s." % [ability_name, _format_cost_summary(missing)]
        elif log == "":
            log = "%s cannot be activated." % ability_name
        return {
            "allowed": false,
            "log": log,
            "missing_costs": missing,
        }
    return {"allowed": true}

func activate(user, context: Dictionary = {}) -> Dictionary:
    var validation := can_activate(user, context)
    if not validation.get("allowed", true):
        validation["success"] = false
        return validation
    if not _apply_costs(user):
        return {
            "success": false,
            "log": "%s could not pay the activation cost." % ability_name,
        }
    var result := _execute_activation(user, context)
    if result == null:
        result = {}
    var success := bool(result.get("success", true))
    result["success"] = success
    if success:
        _start_cooldown()
        _inject_animation_hook(result)
    result["cooldown_remaining"] = get_cooldown_remaining()
    if not result.has("log") or String(result["log"]).is_empty():
        result["log"] = "%s activated." % ability_name if success else "%s fizzles." % ability_name
    return result

func get_cooldown_remaining(now: float = -1.0) -> float:
    if now < 0.0:
        now = _now()
    return max(_cooldown_ready_time - now, 0.0)

func is_on_cooldown() -> bool:
    return get_cooldown_remaining() > 0.0

func reset_cooldown() -> void:
    _cooldown_ready_time = _now()
    emit_signal("cooldown_completed")

func start_cooldown(duration: float) -> void:
    _start_cooldown(duration)

func get_animation_request() -> Dictionary:
    if animation_state == &"":
        return {}
    var request := {
        "state": animation_state,
        "speed": animation_speed,
    }
    if animation_blend_time > 0.0:
        request["blend_time"] = animation_blend_time
    return request

func _execute_activation(_user, _context: Dictionary) -> Dictionary:
    return {"success": true}

func _now() -> float:
    return float(Time.get_ticks_msec()) / 1000.0

func _start_cooldown(duration: float = -1.0) -> void:
    var cd := cooldown if duration < 0.0 else max(duration, 0.0)
    if cd <= 0.0:
        _cooldown_ready_time = _now()
        emit_signal("cooldown_completed")
        return
    _cooldown_ready_time = _now() + cd
    emit_signal("cooldown_started", cd)

func _inject_animation_hook(result: Dictionary) -> void:
    var request := get_animation_request()
    if request.is_empty():
        return
    result["animation_request"] = request

func _apply_costs(user) -> bool:
    if resource_costs.is_empty():
        return true
    if user == null:
        return false
    if user.has_method("apply_resource_costs"):
        return user.apply_resource_costs(resource_costs)
    if user.has_method("modify_resource"):
        for name in resource_costs.keys():
            user.modify_resource(name, -float(resource_costs[name]))
        return true
    return false

func _can_pay_cost(user) -> Dictionary:
    if resource_costs.is_empty():
        return {"ok": true}
    if user == null:
        return {
            "ok": false,
            "missing": resource_costs.duplicate(true),
            "log": "%s requires %s." % [ability_name, _format_cost_summary(resource_costs)],
        }
    if user.has_method("has_resources"):
        if user.has_resources(resource_costs):
            return {"ok": true}
        var missing := {}
        if user.has_method("get_missing_resources"):
            missing = user.get_missing_resources(resource_costs)
        var summary := _format_cost_summary(missing)
        return {
            "ok": false,
            "missing": missing,
            "log": "%s requires %s." % [ability_name, summary],
        }
    if user.has_method("get_resource_amount"):
        var missing_local := {}
        for name in resource_costs.keys():
            var required := float(resource_costs[name])
            var available := float(user.get_resource_amount(name))
            if available + 0.0001 < required:
                missing_local[name] = required - available
        if missing_local.is_empty():
            return {"ok": true}
        return {
            "ok": false,
            "missing": missing_local,
            "log": "%s requires %s." % [ability_name, _format_cost_summary(missing_local)],
        }
    return {
        "ok": false,
        "missing": resource_costs.duplicate(true),
        "log": "%s cannot verify resource requirements." % ability_name,
    }

func _format_cost_summary(costs: Dictionary) -> String:
    if costs.is_empty():
        return "no resources"
    var parts: Array = []
    for key in costs.keys():
        var amount := float(costs[key])
        parts.append("%s x%0.2f" % [str(key), amount])
    return ", ".join(parts)
