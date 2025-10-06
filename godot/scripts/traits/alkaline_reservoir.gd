extends "res://scripts/traits/trait.gd"
class_name AlkalineReservoir

const REGEN_BONUS := 0.2
const DEFENSE_MULTIPLIER := 1.15
const TEAM_BUFF := 0.1

func _init() -> void:
    id = "alkaline_reservoir"
    display_name = "Alkaline Reservoir"
    description = "Stabilising lattice grants steady ion reserves, bolstering team recovery and plating."

func apply(stats: Dictionary, context: Dictionary = {}) -> Dictionary:
    var result := stats.duplicate(true)
    var keywords: Array = result.get("keywords", []).duplicate()
    if "support" not in keywords:
        keywords.append("support")
    result["keywords"] = keywords

    result["defense"] = result.get("defense", 1.0) * DEFENSE_MULTIPLIER
    result["reactivity_regen"] = result.get("reactivity_regen", 0.0) + REGEN_BONUS

    var team_support := result.get("team_support", 0.0)
    team_support += TEAM_BUFF
    result["team_support"] = team_support
    return result
