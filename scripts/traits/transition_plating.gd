extends "res://scripts/traits/trait.gd"
class_name TransitionPlating

const DEFENSE_MULTIPLIER := 1.4
const STABILITY_BONUS := 0.15
const REACTIVITY_TAX := -0.05

func _init() -> void:
    id = "transition_plating"
    display_name = "Transition Plating"
    description = "Dense metallic matrices add layered plating and stability, enabling heavy armour builds."

func apply(stats: Dictionary, context: Dictionary = {}) -> Dictionary:
    var result := stats.duplicate(true)
    var keywords: Array = result.get("keywords", []).duplicate()
    if "heavy_armor" not in keywords:
        keywords.append("heavy_armor")
    result["keywords"] = keywords

    result["defense"] = result.get("defense", 1.0) * DEFENSE_MULTIPLIER
    result["stability"] = result.get("stability", 0.0) + STABILITY_BONUS

    var reactivity := result.get("reactivity", 1.0)
    reactivity += REACTIVITY_TAX
    result["reactivity"] = max(reactivity, 0.0)
    return result
