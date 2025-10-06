extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Higgs Resonance"
    cooldown = 26.0
    activation_duration = 8.0
    description = "Enter a resonance that massively boosts allied stats, then slowly returns them to normal." \
        + " Signature support ultimate."
    activation_profile = {
        "bonuses": {
            "damage": 0.6,
            "shield": 80.0,
        },
        "multipliers": {
            "defense": 1.4,
            "speed": 1.1,
        },
        "keywords": ["higgs", "resonance"],
    }

func activate(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    var result := super.activate(player, context)
    if result.get("success", false):
        player.apply_temporary_profile(self, {
            "multipliers": {
                "damage": 0.85,
                "speed": 0.95,
            },
        }, activation_duration + 4.0)
        result["log"] = "Higgs Resonance peaks then gently cools the field."
    return result
