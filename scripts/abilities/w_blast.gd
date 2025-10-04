extends "res://scripts/abilities/particle_ability.gd"

@export var recoil_penalty: float = 0.15

func _init() -> void:
    ability_name = "W Blast"
    cooldown = 10.0
    activation_duration = 2.5
    description = "Charge up a weak-force burst that hits hard but knocks stability out of balance." \
        + " Self-inflicts a brief defence penalty."
    activation_profile = {
        "bonuses": {
            "damage": 0.8,
        },
        "multipliers": {
            "speed": 1.1,
        },
        "keywords": ["weak_force", "volatile"],
    }

func activate(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    var info := super.activate(player, context)
    if info.get("success", false):
        player.apply_temporary_profile(self, {
            "multipliers": {
                "defense": 1.0 - recoil_penalty,
            },
        }, activation_duration + 1.5)
        info["recoil_penalty"] = recoil_penalty
        info["log"] = "W Blast detonates – recoil reduces defence by %d%%." % int(recoil_penalty * 100.0)
    return info
