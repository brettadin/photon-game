extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Weak Flux"
    cooldown = 14.0
    activation_duration = 5.0
    description = "Focus the weak force into a silent detonation – spreads debuffs while keeping stealth." \
        + " Damage output dips after the pulse."
    activation_profile = {
        "bonuses": {
            "stealth": 0.5,
        },
        "multipliers": {
            "damage": 1.2,
        },
        "keywords": ["stealth", "weak_force"],
    }

func activate(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    var details := super.activate(player, context)
    if details.get("success", false):
        player.apply_temporary_profile(self, {
            "multipliers": {
                "damage": 0.75,
            },
        }, activation_duration + 1.0)
        details["log"] = "Weak Flux ripples outward – energy drain follows the pulse."
    return details
