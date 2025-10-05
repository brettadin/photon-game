extends Node
class_name AbilityCatalog

const Ability := preload("res://scripts/abilities/ability.gd")

const CATALOG: Dictionary = {
    StringName("photon_dash"): preload("res://scripts/abilities/photon_dash.gd"),
    StringName("gluon_bind"): preload("res://scripts/abilities/gluon_bind.gd"),
    StringName("halogen_corrosion"): preload("res://scripts/abilities/halogen_corrosion.gd"),
    StringName("noble_gas_barrier"): preload("res://scripts/abilities/noble_gas_barrier.gd"),
    StringName("weak_charge_field"): preload("res://scripts/abilities/weak_charge_field.gd"),
    StringName("gamma_burst"): preload("res://scripts/abilities/gamma_burst.gd"),
    StringName("baryon_wall"): preload("res://scripts/abilities/baryon_wall.gd"),
    StringName("fusion_lock"): preload("res://scripts/abilities/fusion_lock.gd"),
    StringName("color_dash"): preload("res://scripts/abilities/color_dash.gd"),
    StringName("hadronize"): preload("res://scripts/abilities/hadronize.gd"),
    StringName("annihilation_wave"): preload("res://scripts/abilities/annihilation_wave.gd"),
    StringName("mass_anchor"): preload("res://scripts/abilities/mass_anchor.gd"),
    StringName("phase_shift"): preload("res://scripts/abilities/phase_shift.gd"),
    StringName("ghost_walk"): preload("res://scripts/abilities/ghost_walk.gd"),
    StringName("downward_smash"): preload("res://scripts/abilities/downward_smash.gd"),
    StringName("chain_discharge"): preload("res://scripts/abilities/chain_discharge.gd"),
    StringName("ion_field"): preload("res://scripts/abilities/ion_field.gd"),
    StringName("higgs_mass_boost"): preload("res://scripts/abilities/higgs_mass_boost.gd"),
    StringName("higgs_resonance"): preload("res://scripts/abilities/higgs_resonance.gd"),
    StringName("color_field"): preload("res://scripts/abilities/color_field.gd"),
    StringName("w_blast"): preload("res://scripts/abilities/w_blast.gd"),
    StringName("z_pulse"): preload("res://scripts/abilities/z_pulse.gd"),
    StringName("beta_decay"): preload("res://scripts/abilities/beta_decay.gd"),
    StringName("inertial_field"): preload("res://scripts/abilities/inertial_field.gd"),
    StringName("neutral_screen"): preload("res://scripts/abilities/neutral_screen.gd"),
    StringName("orbital_strike"): preload("res://scripts/abilities/orbital_strike.gd"),
    StringName("refraction_cloak"): preload("res://scripts/abilities/refraction_cloak.gd"),
    StringName("weak_flux"): preload("res://scripts/abilities/weak_flux.gd"),
}

static func get_catalog() -> Dictionary:
    return CATALOG.duplicate()

static func has_ability(id: StringName) -> bool:
    return CATALOG.has(id)

static func create(id: StringName):
    if not CATALOG.has(id):
        return null
    var script: Script = CATALOG[id]
    var ability = script.new()
    if ability is Ability:
        ability.codex_subject_id = String(id)
    return ability

static func build_tooltip(id: StringName) -> String:
    if not CATALOG.has(id):
        return ""
    var ability = create(id)
    if ability == null:
        return ""
    if ability is Ability:
        return ability.get_contextual_tooltip()
    return String(ability)
