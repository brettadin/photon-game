extends Area2D
class_name MoleculeCrafter

signal combo_triggered(player: PlayerAvatar, recipe_id: StringName)
signal combo_failed(player: PlayerAvatar)

@export var reaction_interval: float = 1.25
@export var default_profile: Dictionary = {
    "bonuses": {},
    "multipliers": {
        "speed": 0.85,
        "defense": 0.9,
    },
    "keywords": [StringName("unstable_compound")],
}
@export var default_duration: float = 1.4

@export_group("Combos")
## Array of dictionaries. Supported keys:
##   id: String identifier for the combo
##   tags: Array[StringName] that must all be present
##   mode: "buff", "volatile", or "sustain"
##   profile: Dictionary applied for buff/sustain (optional)
##   duration: Float duration override
##   payload: Dictionary damage payload for volatile reactions
@export var combo_recipes: Array[Dictionary] = [
    {
        "id": "photonic_solution",
        "tags": [StringName("light_control"), StringName("support_inert")],
        "mode": "buff",
        "profile": {
            "bonuses": {
                "speed": 90.0,
                "control": 0.4,
            },
            "multipliers": {
                "damage": 1.1,
            },
            "keywords": [StringName("coherent_light")],
        },
        "duration": 3.5,
    },
    {
        "id": "volatile_slurry",
        "tags": [StringName("reactive_burst"), StringName("toxicity_mastery")],
        "mode": "volatile",
        "payload": {
            "amount": 16.0,
            "source": "chemical_burn",
        },
    },
]

@export_group("Bypass Rules")
@export var bypass_rules: Array[Dictionary] = [
    {
        "tags": [StringName("phase_shift")],
        "reason": "Phased entities cannot bind molecules.",
    },
]

var _tracked_players: Dictionary = {}

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
    for player in _tracked_players.keys().duplicate():
        var data: Dictionary = _tracked_players[player]
        if not is_instance_valid(player):
            _tracked_players.erase(player)
            continue
        data["timer"] += delta
        var interval := float(data.get("interval", reaction_interval))
        if data["timer"] >= interval:
            data["timer"] -= interval
            _process_reaction(player, data)

func _on_body_entered(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    if _matches_bypass_rules(player):
        emit_signal("combo_failed", player)
        return
    var recipe := _resolve_recipe(player)
    _tracked_players[player] = {
        "recipe": recipe,
        "timer": 0.0,
        "interval": float(recipe.get("interval", reaction_interval)),
    }
    _process_reaction(player, _tracked_players[player], true)

func _on_body_exited(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    _tracked_players.erase(body)

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

func _resolve_recipe(player: PlayerAvatar) -> Dictionary:
    for recipe in combo_recipes:
        if typeof(recipe) != TYPE_DICTIONARY:
            continue
        var tags := recipe.get("tags", [])
        if tags.is_empty():
            continue
        var matches := true
        for tag in tags:
            if not player.has_class_tag(StringName(tag)):
                matches = false
                break
        if matches:
            return recipe
    return {
        "id": "default_mix",
        "mode": "sustain",
        "profile": default_profile,
        "duration": default_duration,
    }

func _process_reaction(player: PlayerAvatar, data: Dictionary, immediate: bool = false) -> void:
    if not is_instance_valid(player):
        return
    _ = immediate
    var recipe: Dictionary = data.get("recipe", {})
    var mode := String(recipe.get("mode", "sustain"))
    match mode:
        "buff":
            var profile := recipe.get("profile", default_profile)
            var duration := float(recipe.get("duration", default_duration))
            player.apply_temporary_profile(self, _duplicate_profile(profile), duration)
            emit_signal("combo_triggered", player, StringName(recipe.get("id", "buff")))
        "volatile":
            var payload := recipe.get("payload", {})
            var damage := float(payload.get("amount", 0.0))
            if damage > 0.0:
                var duplicated := payload.duplicate(true)
                duplicated["amount"] = damage
                player.apply_self_damage(duplicated)
            emit_signal("combo_triggered", player, StringName(recipe.get("id", "volatile")))
        _:
            var profile := recipe.get("profile", default_profile)
            var duration := float(recipe.get("duration", default_duration))
            player.apply_temporary_profile(self, _duplicate_profile(profile), duration)
            emit_signal("combo_triggered", player, StringName(recipe.get("id", "sustain")))

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
