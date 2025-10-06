extends "res://scripts/abilities/particle_ability.gd"

@export var recoil_damage: float = 0.3

func _init() -> void:
    ability_name = "Z Pulse"
    cooldown = 9.5
    activation_duration = 2.0
    description = "Neutral weak-force beam that pierces defences but knocks stability into the red." \
        + " Balanced damage and recoil."
    activation_profile = {
        "bonuses": {
            "damage": 0.7,
        },
        "multipliers": {
            "defense": 1.05,
        },
        "keywords": ["weak_force", "neutral"],
    }

func activate(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    var details := super.activate(player, context)
    if details.get("success", false):
        player.apply_temporary_profile(self, {
            "bonuses": {
                "shield": -50.0 * recoil_damage,
            },
            "multipliers": {
                "defense": 1.0 - recoil_damage * 0.5,
            },
        }, activation_duration + 1.0)
        details["log"] = "Z Pulse fires – neutral recoil saps %d%% defence." % int(recoil_damage * 50.0)
    return details
