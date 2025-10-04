extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Fractional Charge"
    description = "Up quark charge tricks electromagnetic puzzles. Increases agility and reaction damage." \
        + " Adds the 'charged' keyword for synergy triggers."
    persistent_profile = {
        "bonuses": {
            "speed": 40.0,
        },
        "multipliers": {
            "damage": 1.1,
            "evasion": 1.15,
        },
        "keywords": ["charged", "evasive"],
    }
