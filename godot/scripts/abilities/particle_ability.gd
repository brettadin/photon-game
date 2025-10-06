extends "res://scripts/abilities/ability.gd"
class_name ParticleAbility

@export var activation_duration: float = 0.0
@export var activation_profile: Dictionary = {}
@export var activation_keywords: Array[StringName] = []
@export var persistent_profile: Dictionary = {}
@export var activation_log_message: String = ""

var slot: StringName = &""

func on_equip(player: PlayerAvatar) -> void:
    if not persistent_profile.is_empty():
        player.apply_stat_profile(self, persistent_profile)

func on_unequip(player: PlayerAvatar) -> void:
    player.remove_stat_profile(self)

func activate(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    return super.activate(player, context)

func _execute_activation(player: PlayerAvatar, context: Dictionary = {}) -> Dictionary:
    if activation_profile.is_empty():
        return {
            "log": "%s is ready." % ability_name,
            "success": false,
        }
    var profile := activation_profile.duplicate(true)
    if not activation_keywords.is_empty():
        var keywords := profile.get("keywords", [])
        for keyword in activation_keywords:
            if keyword not in keywords:
                keywords.append(keyword)
        profile["keywords"] = keywords
    var duration := max(activation_duration, 0.0)
    if duration > 0.0:
        player.apply_temporary_profile(self, profile, duration)
    else:
        player.apply_stat_profile(self, profile)
    var message := activation_log_message if activation_log_message != "" else "%s activated." % ability_name
    var result := {
        "log": message,
        "success": true,
        "duration": duration,
    }
    return _after_activation(player, context, result)

func _after_activation(_player: PlayerAvatar, _context: Dictionary, result: Dictionary) -> Dictionary:
    return result
