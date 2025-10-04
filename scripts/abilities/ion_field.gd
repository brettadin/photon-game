extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Ion Field"
    description = "Electron cloud wraps the avatar, improving control and granting minor shielding." \
        + " Adds the 'conductive' keyword for puzzle hooks."
    persistent_profile = {
        "bonuses": {
            "shield": 15.0,
        },
        "multipliers": {
            "control": 1.2,
        },
        "keywords": ["conductive", "agile"],
    }
