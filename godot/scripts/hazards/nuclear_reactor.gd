extends Area2D
class_name NuclearReactor

signal meltdown_started(current_heat: float)
signal meltdown_stabilized(current_heat: float)
signal reaction_tick(player: PlayerAvatar, reaction_type: StringName, current_heat: float)

@export var ambient_heat_rate: float = 0.35
@export var heat_decay_rate: float = 0.25
@export var meltdown_threshold: float = 10.0
@export var meltdown_burst_damage: float = 32.0
@export var tick_interval: float = 1.0

@export_group("Tag Channels")
@export var fusion_tags: Array[StringName] = [
    StringName("support_reactor"),
    StringName("fusion_specialist"),
]
@export var fission_tags: Array[StringName] = [
    StringName("radiation_aoe"),
    StringName("unstable_decay"),
]

@export_group("Reaction Effects")
@export var fusion_cooling: float = 2.5
@export var fission_heat: float = 1.75
@export var fusion_profile: Dictionary = {
    "bonuses": {
        "shield": 35.0,
    },
    "multipliers": {
        "damage": 1.15,
    },
    "keywords": [StringName("reactor_synergy")],
}
@export var fusion_duration: float = 2.0
@export var fission_payload: Dictionary = {
    "amount": 14.0,
    "source": "reactor_fission",
}

@export_group("Bypass Rules")
@export var bypass_rules: Array[Dictionary] = [
    {
        "tags": [StringName("phase_shift")],
        "reason": "Intangible forms slip through the reactor core.",
    },
]

var _heat: float = 0.0
var _meltdown: bool = false
var _tracked_players: Dictionary = {}

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
    if _tracked_players.is_empty():
        _heat = max(_heat - heat_decay_rate * delta, 0.0)
    else:
        _heat = max(_heat - heat_decay_rate * delta, 0.0)
        _heat += ambient_heat_rate * delta
    for player in _tracked_players.keys().duplicate():
        var data: Dictionary = _tracked_players[player]
        if not is_instance_valid(player):
            _tracked_players.erase(player)
            continue
        data["timer"] += delta
        if data["timer"] >= data.get("interval", tick_interval):
            data["timer"] -= data.get("interval", tick_interval)
            _apply_reaction(player, data)
    if _heat >= meltdown_threshold and not _meltdown:
        _meltdown = true
        emit_signal("meltdown_started", _heat)
        _trigger_meltdown_burst()
    elif _meltdown and _heat < meltdown_threshold * 0.25:
        _meltdown = false
        emit_signal("meltdown_stabilized", _heat)

func _on_body_entered(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    if _matches_bypass_rules(player):
        emit_signal("reaction_tick", player, StringName("bypass"), _heat)
        return
    var mode := _resolve_mode(player)
    if mode == "bypass":
        emit_signal("reaction_tick", player, StringName("bypass"), _heat)
        return
    _tracked_players[player] = {
        "mode": mode,
        "timer": 0.0,
        "interval": tick_interval,
    }
    _apply_reaction(player, _tracked_players[player], true)

func _on_body_exited(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    _tracked_players.erase(body)

func _resolve_mode(player: PlayerAvatar) -> String:
    if player.has_any_class_tag(fusion_tags):
        return "fusion"
    if player.has_any_class_tag(fission_tags):
        return "fission"
    return "neutral"

func _matches_bypass_rules(player: PlayerAvatar) -> bool:
    for rule in bypass_rules:
        if typeof(rule) != TYPE_DICTIONARY:
            continue
        var tags := rule.get("tags", [])
        if tags.is_empty():
            continue
        if player.has_any_class_tag(tags):
            return true
    return false

func _apply_reaction(player: PlayerAvatar, data: Dictionary, immediate: bool = false) -> void:
    if not is_instance_valid(player):
        return
    _ = immediate
    var mode := String(data.get("mode", "neutral"))
    match mode:
        "fusion":
            _heat = max(_heat - fusion_cooling, 0.0)
            player.apply_temporary_profile(self, _duplicate_profile(fusion_profile), fusion_duration)
        "fission":
            _heat += fission_heat
            var payload := fission_payload.duplicate(true)
            payload["amount"] = float(payload.get("amount", 0.0))
            if payload["amount"] > 0.0:
                player.apply_self_damage(payload)
        _:
            if _meltdown:
                var payload := {
                    "amount": meltdown_burst_damage * 0.5,
                    "source": "reactor_meltdown",
                }
                player.apply_self_damage(payload)
    emit_signal("reaction_tick", player, StringName(mode), _heat)
    if _meltdown and mode != "fusion":
        _trigger_meltdown_burst()

func _trigger_meltdown_burst() -> void:
    for player in _tracked_players.keys().duplicate():
        if not is_instance_valid(player):
            _tracked_players.erase(player)
            continue
        var payload := {
            "amount": meltdown_burst_damage,
            "source": "reactor_meltdown",
        }
        player.apply_self_damage(payload)

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
