extends "res://scripts/traits/trait.gd"
class_name ChalcogenCorrosion

const DAMAGE_OVER_TIME := 0.25
const DEFENSE_PIERCING := 0.1

func _init() -> void:
    id = "chalcogen_corrosion"
    display_name = "Chalcogen Corrosion"
    description = "Reactive oxidisers chew through foes with lingering corrosion while ignoring a portion of armour."

func apply(stats: Dictionary, context: Dictionary = {}) -> Dictionary:
    var result := stats.duplicate(true)
    var keywords: Array = result.get("keywords", []).duplicate()
    if "corrosive" not in keywords:
        keywords.append("corrosive")
    result["keywords"] = keywords

    result["damage_over_time"] = result.get("damage_over_time", 0.0) + DAMAGE_OVER_TIME
    result["armor_pierce"] = result.get("armor_pierce", 0.0) + DEFENSE_PIERCING
    return result
