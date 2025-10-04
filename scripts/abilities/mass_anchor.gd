extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Mass Anchor"
    description = "Down quark density bolsters stability, reducing knockback and bolstering shielding." \
        + " Trades away a little agility for toughness."
    persistent_profile = {
        "bonuses": {
            "shield": 35.0,
        },
        "multipliers": {
            "defense": 1.25,
            "speed": 0.9,
        },
        "keywords": ["anchor", "sturdy"],
    }
