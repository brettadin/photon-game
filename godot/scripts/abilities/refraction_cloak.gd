extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Refraction Cloak"
    description = "Wrap in refracted light, upping speed but leaving defences fragile." \
        + " Maintains glass-cannon identity."
    persistent_profile = {
        "bonuses": {
            "speed": 80.0,
        },
        "multipliers": {
            "defense": 0.8,
            "damage": 1.15,
        },
        "keywords": ["light", "fragile"],
    }
