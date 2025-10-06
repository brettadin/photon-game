extends Object
class_name CodexContext

const AbilityCatalog := preload("res://scripts/abilities/ability_catalog.gd")

static var _ability_cache: Dictionary = {}

static var _hazard_catalog := {
    "magnetic_trap": {
        "name": "Magnetic Trap",
        "description": "Superconducting coils pull colour-charged combatants into a confinement lattice while spinning them tangentially.",
        "tip": "Quark and transition-metal builds counter the drag by matching colour charge cycles.",
    },
    "chemical_vat": {
        "name": "Chemical Vat",
        "description": "Open reaction vats aerosolise corrosive reagents that accelerate oxidation and strip shielding.",
        "tip": "Bring coolant pickups or inert gas barriers before triggering volatile combos.",
    },
    "electric_field": {
        "name": "Electric Field",
        "description": "Opposed capacitor plates lace the arena with ionising arcs that punish conductive builds.",
        "tip": "Phase-shifting or inert gas abilities prevent charge runaway.",
    },
    "charged_field": {
        "name": "Charged Field",
        "description": "Rapidly oscillating charge pockets flip polarity to toss targets between potential wells.",
        "tip": "Leptons ignore the colour component but must manage the timing on each reversal.",
    },
    "radiation_zone": {
        "name": "Radiation Zone",
        "description": "Ionising fallout saturates the area, degrading stability and shield integrity over time.",
        "tip": "Purge the zone with weak-force vents or evacuate before decay timers expire.",
    },
    "nuclear_reactor": {
        "name": "Fission Reactor Core",
        "description": "Critical reactor loops vent neutron flux, bathing the field in escalating heat and radiation.",
        "tip": "Gauge boson support and Higgs boosts keep teams coherent long enough to harvest rewards.",
    },
    "molecule_crafter": {
        "name": "Molecule Crafter",
        "description": "Autonomous assemblers rearrange matter into puzzle sequences that demand steady ionic feeds.",
        "tip": "Alkaline earth stabilisers supply the sustained charge needed to finish the sequence safely.",
    },
}

static func get_ability_metadata(id: StringName) -> Dictionary:
    var key := String(id)
    if key.is_empty():
        return {"id": "", "name": "", "description": ""}
    if _ability_cache.has(key):
        return _ability_cache[key].duplicate(true)
    if not AbilityCatalog.has_ability(StringName(id)):
        return {
            "id": key,
            "name": key.capitalize().replace("_", " "),
            "description": "",
            "cooldown": 0.0,
            "resource_costs": {},
        }
    var ability = AbilityCatalog.create(StringName(id))
    if ability == null:
        return {
            "id": key,
            "name": key.capitalize().replace("_", " "),
            "description": "",
            "cooldown": 0.0,
            "resource_costs": {},
        }
    var meta := {
        "id": key,
        "name": String(ability.ability_name),
        "description": String(ability.description),
        "cooldown": float(ability.cooldown),
        "resource_costs": ability.resource_costs.duplicate(true),
    }
    _ability_cache[key] = meta
    return meta.duplicate(true)

static func get_hazard_metadata(id: StringName) -> Dictionary:
    var key := String(id)
    if key.is_empty():
        return {"id": "", "name": "", "description": ""}
    if _hazard_catalog.has(key):
        var data: Dictionary = _hazard_catalog[key]
        return data.duplicate(true)
    return {
        "id": key,
        "name": key.capitalize().replace("_", " "),
        "description": "",
        "tip": "",
    }

static func format_costs(costs: Dictionary) -> String:
    if costs.is_empty():
        return ""
    var parts: Array = []
    for name in costs.keys():
        parts.append("%s x%0.2f" % [String(name), float(costs[name])])
    return ", ".join(parts)
