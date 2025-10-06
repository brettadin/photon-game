extends "res://scripts/traits/trait.gd"
class_name NobleShield

const DEFENSE_MULTIPLIER := 1.35
const TEAM_WARD := 0.2

func _init() -> void:
    id = "noble_shield"
    display_name = "Noble Shield"
    description = "Inert noble gases project stabilising barriers, granting heavy warding to allies without sacrificing focus."

func apply(stats: Dictionary, context: Dictionary = {}) -> Dictionary:
    var result := stats.duplicate(true)
    var keywords: Array = result.get("keywords", []).duplicate()
    if "support" not in keywords:
        keywords.append("support")
    if "heavy_armor" not in keywords:
        keywords.append("heavy_armor")
    result["keywords"] = keywords

    result["defense"] = result.get("defense", 1.0) * DEFENSE_MULTIPLIER
    result["team_barrier"] = result.get("team_barrier", 0.0) + TEAM_WARD
    return result
