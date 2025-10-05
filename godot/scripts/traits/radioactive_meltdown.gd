extends "res://scripts/traits/trait.gd"
class_name RadioactiveMeltdown

const REACTIVITY_MULTIPLIER := 1.4
const DEFENSE_MULTIPLIER := 0.9
const CORRUPTION_BONUS := 0.3
const EXPLOSION_RADIUS := 1.5

func _init() -> void:
    id = "radioactive_meltdown"
    display_name = "Radioactive Meltdown"
    description = "Unstable isotopes surge with corruptive energy, spreading contamination and empowering last-resort detonations."

func apply(stats: Dictionary, context: Dictionary = {}) -> Dictionary:
    var result := stats.duplicate(true)
    var keywords: Array = result.get("keywords", []).duplicate()
    for keyword in ["explosive", "corrosive"]:
        if keyword not in keywords:
            keywords.append(keyword)
    if "contagion" not in keywords:
        keywords.append("contagion")
    result["keywords"] = keywords

    result["reactivity"] = result.get("reactivity", 1.0) * REACTIVITY_MULTIPLIER
    result["defense"] = max(0.0, result.get("defense", 1.0) * DEFENSE_MULTIPLIER)

    result["contagion_strength"] = result.get("contagion_strength", 0.0) + CORRUPTION_BONUS
    result["explosion_radius"] = result.get("explosion_radius", 1.0) * EXPLOSION_RADIUS
    return result
