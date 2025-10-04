extends "res://scripts/abilities/particle_ability.gd"

@export var collapse_penalty: float = 0.4

func _init() -> void:
    ability_name = "Beta Cascade"
    cooldown = 24.0
    activation_duration = 4.5
    description = "Trigger a destructive weak-force cascade, obliterating foes at the cost of severe recoil." \
        + " Leaves stability shattered."
    activation_profile = {
        "bonuses": {
            "damage": 1.2,
        },
        "multipliers": {
            "speed": 1.1,
        },
        "keywords": ["weak_force", "cascade"],
    }

func activate(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    var details := super.activate(player, context)
    if details.get("success", false):
        player.apply_temporary_profile(self, {
            "multipliers": {
                "defense": 1.0 - collapse_penalty,
            },
            "bonuses": {
                "shield": -60.0,
            },
        }, activation_duration + 3.0)
        details["collapse_penalty"] = collapse_penalty
        details["log"] = "Beta Cascade erupts – systems collapse by %d%% afterwards." % int(collapse_penalty * 100.0)
    return details
