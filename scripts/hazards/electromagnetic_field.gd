extends Area2D
class_name ElectromagneticField

signal class_immunity_detected(player: PlayerAvatar)
signal bonus_granted(player: PlayerAvatar, bonus_id: StringName)

@export var field_strength: float = 180.0
@export var repel_positive: bool = true
@export var immune_class_ids: Array[StringName] = []
@export var bonus_keywords: Array[StringName] = [StringName("charged")]
@export var bonus_profile: Dictionary = {
    "bonuses": {
        "speed": 60.0,
    },
    "multipliers": {},
    "keywords": [StringName("energized")],
}

var _tracked_players: Array[PlayerAvatar] = []
var _players_with_bonus: Dictionary = {}

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
    for player in _tracked_players.duplicate():
        if not is_instance_valid(player):
            _tracked_players.erase(player)
            _players_with_bonus.erase(player)
            continue
        var to_center := global_position - player.global_position
        var distance := to_center.length()
        if distance < 1.0:
            continue
        var direction := to_center / distance
        var charge_value := player.charge
        if abs(charge_value) <= 0.001:
            continue
        var attract := charge_value < 0.0 if repel_positive else charge_value > 0.0
        var force_direction := direction if attract else -direction
        player.velocity += force_direction * field_strength * abs(charge_value) * delta

func _on_body_entered(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    if _is_class_immune(player):
        emit_signal("class_immunity_detected", player)
        return
    if player not in _tracked_players:
        _tracked_players.append(player)
    if _should_grant_bonus(player) and not _players_with_bonus.get(player, false):
        player.apply_stat_profile(self, _duplicate_profile(bonus_profile))
        _players_with_bonus[player] = true
        emit_signal("bonus_granted", player, StringName("charge_alignment"))

func _on_body_exited(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    _tracked_players.erase(player)
    if _players_with_bonus.get(player, false):
        player.remove_stat_profile(self)
        _players_with_bonus.erase(player)

func _is_class_immune(player: PlayerAvatar) -> bool:
    if player.particle_class == null:
        return false
    var id := StringName(player.particle_class.id)
    return id in immune_class_ids

func _should_grant_bonus(player: PlayerAvatar) -> bool:
    for keyword in bonus_keywords:
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
