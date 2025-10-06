extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Neutral Screen"
    description = "Z boson's neutrality dampens incoming forces, improving defence at the cost of mobility." \
        + " Ideal for tanking anomalies."
    persistent_profile = {
        "bonuses": {
            "shield": 30.0,
        },
        "multipliers": {
            "defense": 1.35,
            "speed": 0.85,
        },
        "keywords": ["neutral", "tank"],
    }
