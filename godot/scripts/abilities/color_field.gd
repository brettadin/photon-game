extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Color Field"
    description = "Ambient strong-force aura grants allies minor shields and resistance to pulls." \
        + " Ideal for cooperative formations."
    persistent_profile = {
        "bonuses": {
            "shield": 25.0,
        },
        "multipliers": {
            "defense": 1.15,
        },
        "keywords": ["binding", "support"],
    }
