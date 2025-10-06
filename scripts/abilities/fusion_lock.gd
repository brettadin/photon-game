extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Fusion Lock"
    cooldown = 19.0
    activation_duration = 7.0
    description = "Forge a protective fusion lattice. Greatly increases defence and grants the binding keyword." \
        + " Movement slows while maintaining the lock."
    activation_profile = {
        "bonuses": {
            "shield": 90.0,
        },
        "multipliers": {
            "defense": 1.6,
            "speed": 0.8,
        },
        "keywords": ["binding", "fortified"],
    }
    activation_log_message = "Fusion Lock weaves allies into a resilient shell."
