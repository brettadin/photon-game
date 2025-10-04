extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Color Dash"
    cooldown = 6.0
    activation_duration = 2.0
    description = "Accelerate into a blur of colour charge, phasing past hazards." \
        + " Temporarily boosts speed and evasion while reducing control."
    activation_profile = {
        "bonuses": {
            "speed": 160.0,
        },
        "multipliers": {
            "control": 0.6,
            "evasion": 1.35,
        },
        "keywords": ["phased", "fast"],
    }
    activation_log_message = "Color Dash engaged: momentum conserved through phase space."
