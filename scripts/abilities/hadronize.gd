extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Hadronize"
    cooldown = 18.0
    activation_duration = 6.0
    description = "Summon a momentary baryon partner, boosting damage while adding a thin shield." \
        + " Perfect for finishing bursts after building momentum."
    activation_profile = {
        "bonuses": {
            "damage": 0.4,
            "shield": 40.0,
        },
        "multipliers": {
            "control": 0.9,
        },
        "keywords": ["combo", "paired"],
    }
    activation_log_message = "Hadron duo assembled – composite attack online."
