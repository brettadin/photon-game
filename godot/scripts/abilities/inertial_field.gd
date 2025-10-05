extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Inertial Field"
    description = "Persistent Higgs aura raises baseline stability and shield regeneration." \
        + " Slightly reduces top speed due to extra inertia."
    persistent_profile = {
        "bonuses": {
            "shield": 40.0,
        },
        "multipliers": {
            "defense": 1.2,
            "speed": 0.9,
        },
        "keywords": ["higgs", "support"],
    }
