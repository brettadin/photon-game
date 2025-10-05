extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Weak Charge Field"
    description = "Stabilise the W boson's massive charge, boosting damage but lowering long-term stability." \
        + " Keeps the class aggressive."
    persistent_profile = {
        "bonuses": {
            "damage": 0.25,
        },
        "multipliers": {
            "defense": 0.95,
        },
        "keywords": ["weak_force", "aggressive"],
    }
