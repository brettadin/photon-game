extends Node
class_name AbilityCatalog

const CATALOG: Dictionary = {
    StringName("photon_dash"): preload("res://scripts/abilities/photon_dash.gd"),
    StringName("gluon_bind"): preload("res://scripts/abilities/gluon_bind.gd"),
    StringName("halogen_corrosion"): preload("res://scripts/abilities/halogen_corrosion.gd"),
    StringName("noble_gas_barrier"): preload("res://scripts/abilities/noble_gas_barrier.gd"),
    StringName("weak_charge_field"): preload("res://scripts/abilities/weak_charge_field.gd"),
    StringName("gamma_burst"): preload("res://scripts/abilities/gamma_burst.gd"),
}

static func get_catalog() -> Dictionary:
    return CATALOG.duplicate()

static func has_ability(id: StringName) -> bool:
    return CATALOG.has(id)

static func create(id: StringName):
    if not CATALOG.has(id):
        return null
    var script: Script = CATALOG[id]
    return script.new()
