extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Annihilation Wave"
    cooldown = 25.0
    activation_duration = 3.0
    description = "Fire a neutral current that vaporises foes but collapses shields afterwards." \
        + " A risky finisher."
    activation_profile = {
        "bonuses": {
            "damage": 1.4,
        },
        "multipliers": {
            "defense": 1.1,
        },
        "keywords": ["neutral", "annihilation"],
    }

func activate(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    var details := super.activate(player, context)
    if details.get("success", false):
        player.apply_temporary_profile(self, {
            "bonuses": {
                "shield": -100.0,
            },
            "multipliers": {
                "defense": 0.7,
            },
        }, activation_duration + 2.5)
        details["log"] = "Annihilation Wave clears the field – structural integrity plummets."
    return details
