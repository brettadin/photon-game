extends Node
class_name GameController

const ParticleClassDefinition := preload("res://scripts/classes/particle_class.gd")
const PlayerAvatar := preload("res://scripts/player/player_avatar.gd")
const UnlockManager := preload("res://scripts/progression/unlock_manager.gd")
const CodexDatabase := preload("res://scripts/data/codex_database.gd")
const CharacterSelectScene := preload("res://scenes/ui/CharacterSelect.tscn")
const CodexScene := preload("res://scenes/ui/Codex.tscn")
const BoonManager := preload("res://scripts/systems/boon_manager.gd")
const RunModifierSystem := preload("res://scripts/run/modifier_system.gd")

const ABILITY_SCRIPTS := {
    "color_dash": preload("res://scripts/abilities/color_dash.gd"),
    "color_field": preload("res://scripts/abilities/color_field.gd"),
    "fusion_lock": preload("res://scripts/abilities/fusion_lock.gd"),
    "hadronize": preload("res://scripts/abilities/hadronize.gd"),
    "annihilation_wave": preload("res://scripts/abilities/annihilation_wave.gd"),
    "gamma_burst": preload("res://scripts/abilities/gamma_burst.gd"),
    "photon_dash": preload("res://scripts/abilities/photon_dash.gd"),
    "photon_pulse": preload("res://scripts/abilities/photon_pulse.gd"),
    "gluon_bind": preload("res://scripts/abilities/gluon_bind.gd"),
    "ion_field": preload("res://scripts/abilities/ion_field.gd"),
    "noble_gas_barrier": preload("res://scripts/abilities/noble_gas_barrier.gd"),
    "halogen_corrosion": preload("res://scripts/abilities/halogen_corrosion.gd"),
    "higgs_mass_boost": preload("res://scripts/abilities/higgs_mass_boost.gd"),
    "mass_anchor": preload("res://scripts/abilities/mass_anchor.gd"),
    "neutral_screen": preload("res://scripts/abilities/neutral_screen.gd"),
    "w_blast": preload("res://scripts/abilities/w_blast.gd"),
    "z_pulse": preload("res://scripts/abilities/z_pulse.gd"),
    "weak_flux": preload("res://scripts/abilities/weak_flux.gd"),
    "downward_smash": preload("res://scripts/abilities/downward_smash.gd"),
    "phase_shift": preload("res://scripts/abilities/phase_shift.gd"),
    "ghost_walk": preload("res://scripts/abilities/ghost_walk.gd"),
    "chain_discharge": preload("res://scripts/abilities/chain_discharge.gd"),
    "orbital_strike": preload("res://scripts/abilities/orbital_strike.gd"),
    "inertial_field": preload("res://scripts/abilities/inertial_field.gd"),
    "beta_decay": preload("res://scripts/abilities/beta_decay.gd"),
    "higgs_resonance": preload("res://scripts/abilities/higgs_resonance.gd"),
    "weak_charge_field": preload("res://scripts/abilities/weak_charge_field.gd"),
    "fractional_charge": preload("res://scripts/abilities/fractional_charge.gd"),
    "baryon_wall": preload("res://scripts/abilities/baryon_wall.gd"),
}

const CLASS_LOADOUTS := {
    "quark_up": {"active": "color_dash", "passive": "color_field", "ultimate": "fusion_lock"},
    "quark_down": {"active": "mass_anchor", "passive": "color_field", "ultimate": "hadronize"},
    "quark_charm": {"active": "color_dash", "passive": "weak_flux", "ultimate": "annihilation_wave"},
    "quark_strange": {"active": "halogen_corrosion", "passive": "weak_flux", "ultimate": "beta_decay"},
    "quark_top": {"active": "downward_smash", "passive": "fusion_lock", "ultimate": "annihilation_wave"},
    "quark_bottom": {"active": "mass_anchor", "passive": "weak_flux", "ultimate": "beta_decay"},
    "lepton_electron": {"active": "photon_dash", "passive": "photon_pulse", "ultimate": "gamma_burst"},
    "lepton_electron_neutrino": {"active": "phase_shift", "passive": "ghost_walk", "ultimate": "neutral_screen"},
    "lepton_muon": {"active": "photon_dash", "passive": "ion_field", "ultimate": "gamma_burst"},
    "lepton_tau": {"active": "downward_smash", "passive": "ion_field", "ultimate": "annihilation_wave"},
    "boson_photon": {"active": "photon_dash", "passive": "photon_pulse", "ultimate": "gamma_burst"},
    "boson_gluon": {"active": "gluon_bind", "passive": "color_field", "ultimate": "fusion_lock"},
    "boson_w": {"active": "w_blast", "passive": "weak_flux", "ultimate": "annihilation_wave"},
    "boson_z": {"active": "z_pulse", "passive": "weak_flux", "ultimate": "neutral_screen"},
    "boson_higgs": {"active": "higgs_resonance", "passive": "higgs_mass_boost", "ultimate": "mass_anchor"},
    "element_lithium": {"active": "chain_discharge", "passive": "ion_field", "ultimate": "orbital_strike"},
    "element_sodium": {"active": "chain_discharge", "passive": "ion_field", "ultimate": "orbital_strike"},
    "element_potassium": {"active": "chain_discharge", "passive": "ion_field", "ultimate": "orbital_strike"},
    "element_magnesium": {"active": "fusion_lock", "passive": "noble_gas_barrier", "ultimate": "orbital_strike"},
    "element_calcium": {"active": "mass_anchor", "passive": "noble_gas_barrier", "ultimate": "orbital_strike"},
    "element_oxygen": {"active": "halogen_corrosion", "passive": "ion_field", "ultimate": "gamma_burst"},
    "element_sulfur": {"active": "halogen_corrosion", "passive": "ion_field", "ultimate": "gamma_burst"},
    "element_fluorine": {"active": "halogen_corrosion", "passive": "ion_field", "ultimate": "orbital_strike"},
    "element_chlorine": {"active": "halogen_corrosion", "passive": "ion_field", "ultimate": "orbital_strike"},
    "element_iodine": {"active": "halogen_corrosion", "passive": "ion_field", "ultimate": "orbital_strike"},
    "element_helium": {"active": "neutral_screen", "passive": "noble_gas_barrier", "ultimate": "mass_anchor"},
    "element_neon": {"active": "neutral_screen", "passive": "noble_gas_barrier", "ultimate": "orbital_strike"},
    "element_argon": {"active": "neutral_screen", "passive": "noble_gas_barrier", "ultimate": "orbital_strike"},
    "element_iron": {"active": "mass_anchor", "passive": "inertial_field", "ultimate": "orbital_strike"},
    "element_copper": {"active": "chain_discharge", "passive": "ion_field", "ultimate": "orbital_strike"},
    "element_gold": {"active": "mass_anchor", "passive": "inertial_field", "ultimate": "orbital_strike"},
    "element_uranium": {"active": "halogen_corrosion", "passive": "beta_decay", "ultimate": "annihilation_wave"},
    "element_thorium": {"active": "halogen_corrosion", "passive": "beta_decay", "ultimate": "annihilation_wave"},
}

@export var player_path: NodePath
@export var show_selection_on_ready: bool = true

signal run_started(class_data: Dictionary, particle_class: ParticleClassDefinition)
signal boon_options_ready(source: StringName, options: Array)
signal boon_applied(boon_id: StringName, source: StringName, details: Dictionary)

var _unlock_manager := UnlockManager.new()
var _codex_database: CodexDatabase = CodexDatabase.new()
var _selection_ui: Control
var _codex_ui: Codex
var _player: PlayerAvatar
var _boon_manager: BoonManager
var _run_modifier_system: RunModifierSystem

func _ready() -> void:
    _resolve_player()
    _ensure_boon_manager()
    _ensure_modifier_system()
    _ensure_codex_baseline_unlocks()
    if show_selection_on_ready:
        open_character_select()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
        _toggle_pause()
    elif event.is_action_pressed("codex"):
        _open_codex(false)

func open_character_select() -> void:
    if _selection_ui == null:
        _selection_ui = CharacterSelectScene.instantiate()
        add_child(_selection_ui)
        if _selection_ui.has_method("set_unlock_manager"):
            _selection_ui.set_unlock_manager(_unlock_manager)
        if _selection_ui.has_signal("class_chosen"):
            _selection_ui.connect("class_chosen", Callable(self, "_on_class_chosen"))
        if _selection_ui.has_signal("codex_requested"):
            _selection_ui.connect("codex_requested", Callable(self, "_on_codex_requested"))
    _selection_ui.visible = true

func _on_class_chosen(class_data: Dictionary) -> void:
    var particle_class := _build_particle_class(class_data)
    if particle_class == null:
        push_warning("GameController: Unable to build particle class for %s" % class_data.get("id", "unknown"))
        return
    _resolve_player()
    if is_instance_valid(_player):
        _player.set_particle_class(particle_class)
    _ensure_boon_manager()
    if _boon_manager:
        _boon_manager.on_run_started(class_data, particle_class)
    _ensure_modifier_system()
    if _run_modifier_system:
        _run_modifier_system.on_run_started(class_data, particle_class)
    _unlock_codex_for_class(class_data)
    emit_signal("run_started", class_data, particle_class)
    if is_instance_valid(_selection_ui):
        _selection_ui.hide()

func _build_particle_class(class_data: Dictionary) -> ParticleClassDefinition:
    if class_data.is_empty():
        return null
    var definition := ParticleClassDefinition.new()
    definition.id = StringName(class_data.get("id", ""))
    definition.display_name = String(class_data.get("display_name", ""))
    definition.description = String(class_data.get("lore", ""))
    definition.class_tags.clear()
    var ability_tags := class_data.get("ability_tags", [])
    if typeof(ability_tags) == TYPE_ARRAY:
        for tag in ability_tags:
            if typeof(tag) == TYPE_STRING_NAME:
                definition.class_tags.append(tag)
            elif typeof(tag) == TYPE_STRING:
                definition.class_tags.append(StringName(tag))

    var base_stats := class_data.get("base_stats", {})
    if typeof(base_stats) == TYPE_DICTIONARY:
        if base_stats.has("mass_mev"):
            definition.mass = float(base_stats.get("mass_mev", definition.mass))
        elif base_stats.has("atomic_mass"):
            definition.mass = float(base_stats.get("atomic_mass", definition.mass))
        definition.charge = float(base_stats.get("charge", definition.charge))
        definition.stability = float(base_stats.get("stability", definition.stability))

    var loadout_ids := CLASS_LOADOUTS.get(String(class_data.get("id", "")), {})
    definition.active_ability = _ability_from_id(loadout_ids.get("active", ""))
    definition.passive_ability = _ability_from_id(loadout_ids.get("passive", ""))
    definition.ultimate_ability = _ability_from_id(loadout_ids.get("ultimate", ""))
    return definition

func _ability_from_id(id: String) -> Script:
    if id.is_empty():
        return null
    if not ABILITY_SCRIPTS.has(id):
        push_warning("GameController: Ability id %s not registered." % id)
        return null
    return ABILITY_SCRIPTS[id]

func _resolve_player() -> void:
    if is_instance_valid(_player):
        return
    if player_path.is_empty():
        return
    var node := get_node_or_null(player_path)
    if node and node is PlayerAvatar:
        _player = node
        if _boon_manager:
            _boon_manager.set_player(_player)
        if _run_modifier_system:
            _run_modifier_system.set_player(_player)

func _ensure_boon_manager() -> void:
    if _boon_manager:
        if _player:
            _boon_manager.set_player(_player)
        return
    _boon_manager = BoonManager.new()
    _boon_manager.name = "BoonManager"
    add_child(_boon_manager)
    if _player:
        _boon_manager.set_player(_player)
    _boon_manager.boon_options_ready.connect(_on_boon_options_ready)
    _boon_manager.boon_applied.connect(_on_boon_applied)

func _ensure_modifier_system() -> void:
    if _run_modifier_system:
        _run_modifier_system.set_unlock_manager(_unlock_manager)
        if _player:
            _run_modifier_system.set_player(_player)
        return
    _run_modifier_system = RunModifierSystem.new()
    _run_modifier_system.name = "RunModifierSystem"
    add_child(_run_modifier_system)
    _run_modifier_system.set_unlock_manager(_unlock_manager)
    if _player:
        _run_modifier_system.set_player(_player)
    _run_modifier_system.theme_changed.connect(_on_run_theme_changed)
    _run_modifier_system.stage_modifiers_applied.connect(_on_run_stage_modifiers)

func advance_to_stage(stage_index: int, context: Dictionary = {}) -> void:
    if _run_modifier_system == null:
        return
    _run_modifier_system.on_stage_advanced(stage_index, context)

func _on_run_theme_changed(_theme_id: StringName, details: Dictionary) -> void:
    if _boon_manager == null:
        return
    var tags := details.get("tags", [])
    _boon_manager.set_active_theme_tags(tags)

func _on_run_stage_modifiers(_stage_index: int, _modifier_ids: Array) -> void:
    pass

func _ensure_codex_ui() -> void:
    if is_instance_valid(_codex_ui):
        return
    _codex_ui = CodexScene.instantiate()
    _codex_ui.name = "Codex"
    add_child(_codex_ui)
    _codex_ui.close_requested.connect(_on_codex_close_requested)
    if _codex_ui.has_method("set_unlock_manager"):
        _codex_ui.set_unlock_manager(_unlock_manager)
    _codex_ui.hide_codex()

func _ensure_codex_baseline_unlocks() -> void:
    if _codex_database == null:
        _codex_database = CodexDatabase.new()
    var baseline := _codex_database.entries_for_unlock("", "")
    if not baseline.is_empty():
        _unlock_manager.unlock_codex_entries(baseline)
    _ensure_codex_ui()

func _open_codex(resume_on_close: bool) -> void:
    _ensure_codex_ui()
    if _codex_ui == null:
        return
    _codex_ui.set_unlock_manager(_unlock_manager)
    _codex_ui.set_resume_on_close(resume_on_close)
    _codex_ui.refresh_entries()
    _codex_ui.show_codex()

func _toggle_pause() -> void:
    var tree := get_tree()
    tree.paused = not tree.paused
    if tree.paused:
        _open_codex(true)
    elif is_instance_valid(_codex_ui):
        _codex_ui.hide_codex()

func _on_codex_close_requested(resume_on_close: bool) -> void:
    if resume_on_close:
        var tree := get_tree()
        tree.paused = false

func _on_codex_requested() -> void:
    _open_codex(false)

func _unlock_codex_for_class(class_data: Dictionary) -> void:
    if _codex_database == null:
        _codex_database = CodexDatabase.new()
    var category := String(class_data.get("category", ""))
    var group := String(class_data.get("group", ""))
    var ids := _codex_database.entries_for_unlock(category, group)
    if ids.is_empty():
        return
    _unlock_manager.unlock_codex_entries(ids)
    if is_instance_valid(_codex_ui):
        _codex_ui.refresh_entries()

func set_level_theme_tags(tags: Array) -> void:
    _ensure_boon_manager()
    if _boon_manager:
        _boon_manager.set_active_theme_tags(tags)

func register_enemy_boon_drop(enemy_context: Dictionary = {}) -> void:
    _ensure_boon_manager()
    if _boon_manager:
        _boon_manager.roll_enemy_drop(enemy_context)

func register_event_boon(event_context: Dictionary = {}) -> void:
    _ensure_boon_manager()
    if _boon_manager:
        _boon_manager.roll_event_room(event_context)

func register_shop_boons(shop_context: Dictionary = {}) -> void:
    _ensure_boon_manager()
    if _boon_manager:
        _boon_manager.roll_shop_inventory(shop_context)

func apply_boon(boon_id: StringName, source: StringName = &"manual", context: Dictionary = {}) -> Dictionary:
    _ensure_boon_manager()
    if _boon_manager:
        return _boon_manager.apply_boon(boon_id, source, context)
    return {}

func clear_run_boons() -> void:
    if _boon_manager:
        _boon_manager.clear_all_boons()

func _on_boon_options_ready(source: StringName, options: Array) -> void:
    emit_signal("boon_options_ready", source, options)

func _on_boon_applied(boon_id: StringName, source: StringName, details: Dictionary) -> void:
    emit_signal("boon_applied", boon_id, source, details)
