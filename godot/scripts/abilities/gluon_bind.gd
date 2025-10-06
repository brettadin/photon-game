extends "res://scripts/abilities/particle_ability.gd"

@export var tether_strength: float = 0.8
@export var tether_duration: float = 5.0
@export var energy_cost: float = 35.0

func _init() -> void:
    ability_name = "Gluon Bind"
    cooldown = 9.0
    activation_duration = tether_duration
    resource_costs = {&"energy": energy_cost}
    description = "Project a strong-force tether that links allies or snares foes, boosting defence while active." \
        + " Enemies struggle to escape the colour flux."
    activation_profile = {
        "bonuses": {
            "shield": 45.0,
        },
        "multipliers": {
            "defense": 1.25,
        },
        "keywords": ["binding", "support"],
    }
    animation_state = &"cast"
    animation_speed = 0.9

func _after_activation(player: PlayerAvatar, context: Dictionary, result: Dictionary) -> Dictionary:
    var target = context.get("target")
    if target == null:
        return result
    if target == player:
        return result
    if not target.has_method("get_status_manager"):
        return result
    var manager = target.get_status_manager()
    if manager == null:
        return result
    var status_data := {
        "tags": [StringName("strong_force"), StringName("binding")],
        "tether_strength": tether_strength,
    }
    var applied := manager.apply_status(&"bound", tether_duration, status_data, player)
    result["tether_status"] = applied
    if applied.get("immune", false):
        result["log"] += " Target resists the colour flux."
    elif applied.get("success", false):
        result["log"] += " Target is caught in the gluon weave (strength %0.2f)." % tether_strength
    return result
