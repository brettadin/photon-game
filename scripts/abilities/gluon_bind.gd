extends "res://scripts/abilities/particle_ability.gd"

@export var tether_strength: float = 0.8

func _init() -> void:
    ability_name = "Gluon Bind"
    cooldown = 9.0
    activation_duration = 5.0
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

func activate(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    var details := super.activate(player, context)
    if details.get("success", false):
        details["tether_strength"] = tether_strength
        details["log"] = "Gluon Bind forms a colour flux tether (strength %0.2f)." % tether_strength
    return details
