extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Chain Discharge"
    cooldown = 16.0
    activation_duration = 4.0
    description = "Rapidly arc between foes, massively boosting damage while draining shields afterwards." \
        + " Requires precise timing to avoid vulnerability."
    activation_profile = {
        "bonuses": {
            "damage": 0.75,
            "shield": 30.0,
        },
        "multipliers": {
            "control": 1.4,
        },
        "keywords": ["chain", "conductive"],
    }

func activate(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    var result := super.activate(player, context)
    if result.get("success", false):
        # Schedule a post-activation penalty by applying a negative shield profile once the boost fades.
        player.apply_temporary_profile(self, {
            "bonuses": {
                "shield": -40.0,
            },
            "multipliers": {
                "defense": 0.85,
            },
        }, activation_duration + 0.1)
        result["log"] = "Chain Discharge arcs wildly – shields destabilise afterwards."
    return result
