extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Gamma Burst"
    cooldown = 22.0
    activation_duration = 3.5
    description = "Release a devastating gamma flash. Massive damage spike with a steep stability penalty afterwards." \
        + " Use only when escape is assured."
    activation_profile = {
        "bonuses": {
            "damage": 1.1,
        },
        "multipliers": {
            "speed": 1.4,
        },
        "keywords": ["light", "gamma"],
    }

func activate(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    var details := super.activate(player, context)
    if details.get("success", false):
        player.apply_temporary_profile(self, {
            "bonuses": {
                "shield": -80.0,
            },
            "multipliers": {
                "defense": 0.6,
            },
        }, activation_duration + 2.0)
        details["log"] = "Gamma Burst annihilates targets – defences collapse afterwards."
    return details
