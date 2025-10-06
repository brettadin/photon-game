extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Mass Infusion"
    cooldown = 11.0
    activation_duration = 6.0
    description = "Channel the Higgs field to increase mass and defence for allies while slowing movement." \
        + " Great for prepping heavy attacks."
    activation_profile = {
        "bonuses": {
            "shield": 60.0,
        },
        "multipliers": {
            "defense": 1.4,
            "speed": 0.85,
        },
        "keywords": ["higgs", "empower"],
    }
    activation_log_message = "Mass Infusion bathes the squad in Higgs energy."
