extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Baryon Wall"
    cooldown = 20.0
    activation_duration = 8.0
    description = "Lock neighbouring quarks into a defensive lattice, dramatically raising shielding and defense." \
        + " Slightly slows movement while active."
    activation_profile = {
        "bonuses": {
            "shield": 120.0,
        },
        "multipliers": {
            "defense": 1.5,
            "speed": 0.75,
        },
        "keywords": ["fortress", "bound"],
    }
    activation_log_message = "Baryon Wall formed – incoming momentum absorbed."
