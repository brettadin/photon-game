extends "res://scripts/traits/trait.gd"
class_name AlkaliOverload

const REACTIVITY_MULTIPLIER := 1.25
const REACTIVITY_BONUS := 0.35
const DEFENSE_MULTIPLIER := 0.8

func _init() -> void:
    id = "alkali_overload"
    display_name = "Alkali Overload"
    description = "Unstable charge releases explosive bursts, massively raising reactivity while trading away plating."

func apply(stats: Dictionary, context: Dictionary = {}) -> Dictionary:
    var result := stats.duplicate(true)
    var keywords: Array = result.get("keywords", []).duplicate()
    if "explosive" not in keywords:
        keywords.append("explosive")
    result["keywords"] = keywords

    var reactivity := result.get("reactivity", 1.0)
    reactivity *= REACTIVITY_MULTIPLIER
    reactivity += REACTIVITY_BONUS
    result["reactivity"] = reactivity

    var defense := result.get("defense", 1.0)
    defense *= DEFENSE_MULTIPLIER
    result["defense"] = max(defense, 0.0)

    var bursts := result.get("burst_damage", 0.0)
    bursts += REACTIVITY_BONUS * 2.0
    result["burst_damage"] = bursts
    return result
