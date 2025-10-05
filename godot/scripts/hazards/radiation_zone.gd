extends Area2D
class_name RadiationZone

signal class_immunity_detected(player: PlayerAvatar)
signal radiation_tick(player: PlayerAvatar, intensity: float)
signal radiation_resisted(player: PlayerAvatar)

@export var intensity: float = 0.75
@export var tick_interval: float = 1.0
@export var immune_class_ids: Array[StringName] = []
@export var resistant_keywords: Array[StringName] = [StringName("stable")]
@export var radiation_profile: Dictionary = {
    "bonuses": {},
    "multipliers": {
        "defense": 0.9,
    },
    "keywords": [StringName("irradiated")],
}
@export var profile_duration: float = 1.2

var _exposed_players: Dictionary = {}

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
    for player in _exposed_players.keys().duplicate():
        var data: Dictionary = _exposed_players.get(player)
        if data == null:
            _exposed_players.erase(player)
            continue
        if not is_instance_valid(player):
            _exposed_players.erase(player)
            continue
        data["timer"] += delta
        if data["timer"] >= tick_interval:
            data["timer"] -= tick_interval
            _apply_radiation(player)

func _on_body_entered(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    if _is_class_immune(player):
        emit_signal("class_immunity_detected", player)
        return
    if _is_resistant(player):
        emit_signal("radiation_resisted", player)
        return
    _exposed_players[player] = {"timer": 0.0}
    _apply_radiation(player)

func _on_body_exited(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    _exposed_players.erase(player)

func _apply_radiation(player: PlayerAvatar) -> void:
    if not is_instance_valid(player):
        return
    player.apply_temporary_profile(self, _duplicate_profile(radiation_profile), profile_duration)
    emit_signal("radiation_tick", player, intensity)

func _is_class_immune(player: PlayerAvatar) -> bool:
    if player.particle_class == null:
        return false
    return StringName(player.particle_class.id) in immune_class_ids

func _is_resistant(player: PlayerAvatar) -> bool:
    for keyword in resistant_keywords:
        if player.has_keyword(keyword):
            return true
    return false

func _duplicate_profile(profile: Dictionary) -> Dictionary:
    var result := {
        "bonuses": {},
        "multipliers": {},
        "keywords": [],
    }
    if profile.has("bonuses"):
        result["bonuses"] = profile["bonuses"].duplicate(true)
    if profile.has("multipliers"):
        result["multipliers"] = profile["multipliers"].duplicate(true)
    if profile.has("keywords"):
        result["keywords"] = profile["keywords"].duplicate()
    return result
