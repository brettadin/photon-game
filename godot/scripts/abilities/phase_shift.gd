extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Phase Shift"
    cooldown = 8.0
    activation_duration = 3.0
    description = "Slip out of phase with matter, ignoring collisions while reducing outgoing damage." \
        + " Perfect infiltration tool."
    activation_profile = {
        "bonuses": {
            "stealth": 1.0,
        },
        "multipliers": {
            "damage": 0.6,
            "evasion": 1.5,
        },
        "keywords": ["intangible", "stealth"],
    }
    activation_log_message = "Phase Shift renders the neutrino ghostlike."
