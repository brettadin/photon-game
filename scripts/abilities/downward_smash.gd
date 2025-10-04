extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Downward Smash"
    cooldown = 7.0
    activation_duration = 2.5
    description = "Convert heft into a seismic slam. Hits hard but momentarily reduces mobility." \
        + " Excellent for cracking armour." 
    activation_profile = {
        "bonuses": {
            "damage": 0.5,
        },
        "multipliers": {
            "speed": 0.65,
            "control": 0.8,
        },
        "keywords": ["heavy", "impact"],
    }
    activation_log_message = "Downward Smash rattles the arena with colour-neutral force."
