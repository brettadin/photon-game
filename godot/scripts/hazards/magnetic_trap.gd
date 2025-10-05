extends Area2D
class_name MagneticTrap

signal class_immunity_detected(player: PlayerAvatar)
signal hadron_combined(players: Array)
signal bonus_granted(player: PlayerAvatar, bonus_id: StringName)

@export var trap_strength: float = 220.0
@export var immune_class_ids: Array[StringName] = []
@export var baryon_recipe: Array[StringName] = [StringName("up_quark"), StringName("up_quark"), StringName("down_quark")]
@export var hadron_bonus_profile: Dictionary = {
    "bonuses": {
        "damage": 0.5,
    },
    "multipliers": {
        "defense": 1.2,
    },
    "keywords": [StringName("hadronized")],
}
@export var hadron_bonus_duration: float = 4.0

var _tracked_players: Array[PlayerAvatar] = []
var _hadronized_players: Array[PlayerAvatar] = []

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
    for player in _tracked_players.duplicate():
        if not is_instance_valid(player):
            _tracked_players.erase(player)
            continue
        var to_center := global_position - player.global_position
        var distance := max(to_center.length(), 1.0)
        var pull := to_center.normalized() * trap_strength * delta
        var tangential := Vector2(-to_center.y, to_center.x).normalized() * trap_strength * 0.5 * delta
        player.velocity += pull + tangential / max(distance / 64.0, 1.0)
    _try_hadronize()

func _on_body_entered(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    if _is_class_immune(player):
        emit_signal("class_immunity_detected", player)
        return
    if player not in _tracked_players:
        _tracked_players.append(player)

func _on_body_exited(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    _tracked_players.erase(player)
    _hadronized_players.erase(player)

func _try_hadronize() -> void:
    if baryon_recipe.is_empty():
        return
    var counts := {}
    for class_id in baryon_recipe:
        counts[class_id] = counts.get(class_id, 0) + 1
    var matches: Array[PlayerAvatar] = []
    var temp_counts := counts.duplicate(true)
    for player in _tracked_players:
        if not is_instance_valid(player):
            continue
        if player.particle_class == null:
            continue
        var id := StringName(player.particle_class.id)
        if temp_counts.get(id, 0) > 0 and player not in _hadronized_players:
            matches.append(player)
            temp_counts[id] -= 1
    for remaining in temp_counts.values():
        if remaining > 0:
            return
    if matches.size() != baryon_recipe.size():
        return
    for player in matches:
        player.apply_temporary_profile(self, _duplicate_profile(hadron_bonus_profile), hadron_bonus_duration)
        _hadronized_players.append(player)
        emit_signal("bonus_granted", player, StringName("hadron_bonus"))
    emit_signal("hadron_combined", matches.duplicate())

func _is_class_immune(player: PlayerAvatar) -> bool:
    if player.particle_class == null:
        return false
    return StringName(player.particle_class.id) in immune_class_ids

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
