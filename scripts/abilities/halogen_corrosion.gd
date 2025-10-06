extends "res://scripts/abilities/ability.gd"

@export var corrosion_duration: float = 4.0
@export var defense_penalty: float = -22.0
@export var corrosion_damage_per_second: float = 6.0
@export var energy_cost: float = 18.0

func _init() -> void:
    ability_name = "Halogen Corrosion"
    cooldown = 7.0
    resource_costs = {&"energy": energy_cost}
    description = "Atomise a volatile halogen cloud that strips protective layers and scars unstable particles." \
        + " Applies a corrosive status that gnaws at defence and punishes instability."
    animation_state = &"cast"
    animation_speed = 1.1

func _execute_activation(user, context: Dictionary = {}) -> Dictionary:
    var target = context.get("target")
    if target == null:
        return {
            "success": false,
            "log": "Halogen Corrosion requires a target.",
        }
    var duration := context.get("duration", corrosion_duration)
    var log_message := "%s bathes the target in reactive ions." % ability_name
    var profile_applied := false
    if target.has_method("apply_temporary_profile"):
        var profile := {
            "bonuses": {"defense": defense_penalty},
            "keywords": [StringName("corroded")],
        }
        target.apply_temporary_profile(self, profile, duration)
        log_message += " Defensive plating is etched away."
        profile_applied = true
    var status_result := _apply_corrosion_status(target, duration, user)
    if status_result.get("immune", false):
        log_message += " Target structure is immune to corrosion."
    elif status_result.get("success", false):
        log_message += " Corrosion gnaws for %0.1fs." % duration
    return {
        "success": profile_applied or status_result.get("success", false),
        "log": log_message,
        "status": status_result,
        "duration": duration,
    }

func _apply_corrosion_status(target, duration: float, source) -> Dictionary:
    if not target.has_method("get_status_manager"):
        return {"success": false}
    var manager = target.get_status_manager()
    if manager == null:
        return {"success": false}
    var status_data := {
        "tags": [StringName("corrosion"), StringName("chemical")],
        "self_damage": {
            "per_second": corrosion_damage_per_second,
            "scales_with_instability": true,
            "type": StringName("etching"),
        },
    }
    return manager.apply_status(&"corroded", duration, status_data, source)
