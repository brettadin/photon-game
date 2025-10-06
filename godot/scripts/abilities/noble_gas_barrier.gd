extends "res://scripts/abilities/particle_ability.gd"

@export var barrier_shield_bonus: float = 120.0
@export var barrier_defense_multiplier: float = 1.4
@export var barrier_duration: float = 6.0
@export var energy_cost: float = 24.0

func _init() -> void:
    ability_name = "Noble Gas Barrier"
    cooldown = 10.0
    activation_duration = barrier_duration
    resource_costs = {&"energy": energy_cost}
    description = "Condense inert noble gases into a lattice that absorbs incoming energy and stabilises allies." \
        + " Provides a sturdy barrier and grants damage resistance while it persists."
    activation_profile = {
        "bonuses": {
            "shield": barrier_shield_bonus,
        },
        "multipliers": {
            "defense": barrier_defense_multiplier,
        },
        "keywords": [StringName("barrier"), StringName("stable")],
    }
    activation_log_message = "Noble Gas Barrier crystallises into a radiant shell."
    animation_state = &"shield"
    animation_speed = 0.9

func _after_activation(player: PlayerAvatar, context: Dictionary, result: Dictionary) -> Dictionary:
    var target = context.get("target")
    if target == null:
        target = player
    if not target.has_method("get_status_manager"):
        return result
    var manager = target.get_status_manager()
    if manager == null:
        return result
    var status_data := {
        "tags": [StringName("barrier"), StringName("shield")],
        "absorption": barrier_shield_bonus,
        "self_damage": {
            "per_second": 0.0,
            "scales_with_instability": false,
        },
    }
    var applied := manager.apply_status(&"barrier", barrier_duration, status_data, player)
    result["barrier_status"] = applied
    if applied.get("success", false):
        result["log"] += " Protective gases damp incoming force."
    return result
