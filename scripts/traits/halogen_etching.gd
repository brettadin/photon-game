extends "res://scripts/traits/trait.gd"
class_name HalogenEtching

const REACTIVITY_MULTIPLIER := 1.15
const DEFENSE_SHRED := 0.15
const STATUS_DURATION := 2.0

func _init() -> void:
    id = "halogen_etching"
    display_name = "Halogen Etching"
    description = "Highly electronegative halogens etch defences, increasing reactivity and applying stacking armour shred."

func apply(stats: Dictionary, context: Dictionary = {}) -> Dictionary:
    var result := stats.duplicate(true)
    var keywords: Array = result.get("keywords", []).duplicate()
    if "corrosive" not in keywords:
        keywords.append("corrosive")
    if "explosive" in keywords and "volatile" not in keywords:
        keywords.append("volatile")
    result["keywords"] = keywords

    result["reactivity"] = result.get("reactivity", 1.0) * REACTIVITY_MULTIPLIER

    var shred := result.get("enemy_armor_shred", 0.0)
    shred += DEFENSE_SHRED
    result["enemy_armor_shred"] = shred

    var status := result.get("status_durations", {})
    status = status.duplicate()
    status["etching"] = status.get("etching", 0.0) + STATUS_DURATION
    result["status_durations"] = status
    return result
