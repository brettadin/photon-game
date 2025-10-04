extends Area2D
class_name ChemicalVat

signal class_immunity_detected(player: PlayerAvatar)
signal molecule_crafted(player: PlayerAvatar, molecule_id: StringName)
signal bonus_granted(player: PlayerAvatar, bonus_id: StringName)

@export var immune_class_ids: Array[StringName] = []
@export var crafting_recipes: Dictionary = {
    "explosive": {
        "molecule": "volatile_solution",
        "profile": {
            "bonuses": {"damage": 0.35},
            "multipliers": {"defense": 0.9},
            "keywords": [StringName("volatile")],
        },
        "duration": 5.0,
    },
    "corrosive": {
        "molecule": "acidic_slurry",
        "profile": {
            "bonuses": {"control": 0.2},
            "multipliers": {},
            "keywords": [StringName("acidic")],
        },
        "duration": 4.0,
    },
}
@export var default_duration: float = 3.0

var _active_players: Dictionary = {}

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    if _is_class_immune(player):
        emit_signal("class_immunity_detected", player)
        return
    var recipe := _get_recipe_for_player(player)
    if recipe.is_empty():
        return
    var profile := recipe.get("profile", {})
    var duration := float(recipe.get("duration", default_duration))
    player.apply_temporary_profile(self, _duplicate_profile(profile), duration)
    var molecule_id := StringName(recipe.get("molecule", "unknown_compound"))
    _active_players[player] = molecule_id
    emit_signal("molecule_crafted", player, molecule_id)
    emit_signal("bonus_granted", player, StringName("alchemy_bonus"))

func _on_body_exited(body: Node) -> void:
    if not (body is PlayerAvatar):
        return
    var player := body as PlayerAvatar
    _active_players.erase(player)

func _is_class_immune(player: PlayerAvatar) -> bool:
    if player.particle_class == null:
        return false
    return StringName(player.particle_class.id) in immune_class_ids

func _get_recipe_for_player(player: PlayerAvatar) -> Dictionary:
    for key in crafting_recipes.keys():
        var keyword := StringName(key)
        if player.has_keyword(keyword):
            var recipe = crafting_recipes[key]
            if recipe is Dictionary:
                return recipe
    return {}

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
