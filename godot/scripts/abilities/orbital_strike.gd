extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Orbital Strike"
    cooldown = 5.5
    activation_duration = 1.8
    description = "Zip around a target and unleash an electron spiral, boosting damage and control briefly." \
        + " Restores a little shield on hit." 
    activation_profile = {
        "bonuses": {
            "damage": 0.35,
            "shield": 20.0,
        },
        "multipliers": {
            "control": 1.3,
        },
        "keywords": ["orbit", "charged"],
    }
    activation_log_message = "Orbital Strike discharges across the lattice."
