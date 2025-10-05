extends "res://scripts/abilities/particle_ability.gd"

func _init() -> void:
    ability_name = "Photon Pulse"
    cooldown = 4.5
    activation_duration = 1.5
    description = "Explode forward at light-speed, spiking damage but shedding shields." \
        + " Classic glass-cannon burst."
    activation_profile = {
        "bonuses": {
            "damage": 0.55,
        },
        "multipliers": {
            "speed": 1.6,
        },
        "keywords": ["light", "burst"],
    }

func activate(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    var outcome := super.activate(player, context)
    if outcome.get("success", false):
        player.apply_temporary_profile(self, {
            "bonuses": {
                "shield": -30.0,
            },
            "multipliers": {
                "defense": 0.8,
            },
        }, activation_duration + 0.5)
        outcome["log"] = "Photon Pulse scorches forward – defences flare out."
    return outcome
