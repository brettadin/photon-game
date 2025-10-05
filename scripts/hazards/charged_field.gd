extends Area2D
class_name ChargedField

signal player_forced(player: PlayerAvatar, mode: StringName, strength: float)
signal player_bypassed(player: PlayerAvatar)

@export var field_strength: float = 240.0
@export var falloff_radius: float = 240.0
@export_enum("charge_based", "neutral") var default_mode: String = "charge_based"
@export var attract_positive_charge: bool = false
@export var attract_negative_charge: bool = true

@export_group("Tag Driven Behaviour")
## Array of dictionaries. Each entry supports the keys:
##   tags: Array[StringName] required
##   mode: "attract", "repel", "neutral", or "bypass"
##   force_multiplier: Float multiplier applied to the base strength
@export var tag_force_rules: Array[Dictionary] = [
    {
        "tags": [StringName("electric_tricks")],
        "mode": "attract",
        "force_multiplier": 1.15,
    },
    {
        "tags": [StringName("magnetic_control")],
        "mode": "repel",
        "force_multiplier": 1.0,
    },
]

@export_group("Bypass Rules")
## Array of dictionaries. Each entry supports the keys:
##   tags: Array[StringName]
##   reason: String (optional metadata for designers)
@export var bypass_rules: Array[Dictionary] = [
    {
        "tags": [StringName("phase_shift")],
        "reason": "Phase-shifted particles bypass the electromagnetic field.",
    },
]

var _tracked_players: Array[PlayerAvatar] = []
var _cached_rules: Dictionary = {}

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
    if _tracked_players.is_empty():
        return
    for player in _tracked_players.duplicate():
        if not is_instance_valid(player):
            _tracked_players.erase(player)
            _cached_rules.erase(player)
            continue
        var rule: Dictionary = _cached_rules.get(player, {})
        if _rule_is_bypass(rule) or _matches_bypass_rules(player):
            continue
        var force := _evaluate_force(player, rule)
        if force == Vector2.ZERO:
            continue
        player.velocity += force * delta
        emit_signal("player_forced", player, StringName(rule.get("mode", _default_mode_key(player))), force.length())

func _on_body_entered(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    var rule := _resolve_rule(player)
    _cached_rules[player] = rule
    if _rule_is_bypass(rule) or _matches_bypass_rules(player):
        emit_signal("player_bypassed", player)
        return
    if player not in _tracked_players:
        _tracked_players.append(player)

func _on_body_exited(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    _tracked_players.erase(player)
    _cached_rules.erase(player)

func _resolve_rule(player: PlayerAvatar) -> Dictionary:
    for rule in tag_force_rules:
        if typeof(rule) != TYPE_DICTIONARY:
            continue
        var tags := rule.get("tags", [])
        if tags.is_empty():
            continue
        if player.has_any_class_tag(tags):
            return rule
    return {}

func _rule_is_bypass(rule: Dictionary) -> bool:
    if rule.is_empty():
        return false
    var mode := String(rule.get("mode", ""))
    if mode == "bypass":
        return true
    return bool(rule.get("bypass", false))

func _matches_bypass_rules(player: PlayerAvatar) -> bool:
    for entry in bypass_rules:
        if typeof(entry) != TYPE_DICTIONARY:
            continue
        var tags := entry.get("tags", [])
        if tags.is_empty():
            continue
        if player.has_any_class_tag(tags):
            return true
    return false

func _evaluate_force(player: PlayerAvatar, rule: Dictionary) -> Vector2:
    var to_center := global_position - player.global_position
    var distance := to_center.length()
    if distance < 0.01:
        return Vector2.ZERO
    var direction := to_center / distance
    var multiplier := float(rule.get("force_multiplier", 1.0))
    var mode := String(rule.get("mode", ""))
    if mode == "attract":
        return direction * _compute_strength(distance) * multiplier
    elif mode == "repel":
        return -direction * _compute_strength(distance) * multiplier
    elif mode == "neutral":
        return Vector2.ZERO
    return _evaluate_default_force(player, direction, distance, multiplier)

func _default_mode_key(player: PlayerAvatar) -> String:
    var rule := _cached_rules.get(player, {})
    if typeof(rule) == TYPE_DICTIONARY and rule.has("mode"):
        return String(rule["mode"])
    return default_mode

func _evaluate_default_force(player: PlayerAvatar, direction: Vector2, distance: float, multiplier: float) -> Vector2:
    if default_mode != "charge_based":
        return Vector2.ZERO
    var charge := player.charge
    if abs(charge) <= 0.001:
        return Vector2.ZERO
    var attract_direction := direction
    var is_positive := charge > 0.0
    if is_positive:
        if not attract_positive_charge:
            attract_direction = -direction
    else:
        if not attract_negative_charge:
            attract_direction = -direction
    var strength := _compute_strength(distance) * multiplier * max(abs(charge), 0.25)
    return attract_direction * strength

func _compute_strength(distance: float) -> float:
    if falloff_radius <= 0.0:
        return field_strength
    var normalized := clamp(distance / falloff_radius, 0.0, 1.0)
    return field_strength * (1.0 - normalized)
