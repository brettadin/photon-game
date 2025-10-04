extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Ghost Walk"
    description = "Neutrino barely interacts – permanent stealth bonus and resistance to binding."
    persistent_profile = {
        "bonuses": {
            "stealth": 0.6,
        },
        "multipliers": {
            "evasion": 1.25,
        },
        "keywords": ["stealth", "untetherable"],
    }
