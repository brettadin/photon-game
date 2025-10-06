extends Control
class_name CharacterSelect

const ClassDatabase := preload("res://scripts/data/class_database.gd")
const UnlockManager := preload("res://scripts/progression/unlock_manager.gd")
const CodexService := preload("res://scripts/data/codex_service.gd")

signal class_chosen(class_data: Dictionary)
signal codex_requested

@onready var _status_label: Label = %StatusLabel
@onready var _tab_container: TabContainer = %RosterTabs
@onready var _standard_model_list: VBoxContainer = %StandardModelList
@onready var _element_list: VBoxContainer = %ElementList
@onready var _codex_button: Button = %CodexButton

var _database: ClassDatabase
var _unlock_manager: UnlockManager
var _selected_panel: PanelContainer = null

const TAG_SUMMARIES := {
    "agile_skirmisher": "Thrives on rapid repositioning and precision strikes.",
    "color_binding": "Rewards coordinating allies with tether combos.",
    "baryon_synergy": "Leverages team combos for amplified damage.",
    "defense_anchor": "Plays as a frontline anchor with extra resilience.",
    "burst_damage": "Delivers burst windows that require careful timing.",
    "unstable_decay": "Trades stability for massive spikes—manage decay carefully.",
    "status_decay": "Stacks lingering debuffs to wear opponents down.",
    "debuff_specialist": "Focuses on weakening enemies over time.",
    "gravity_crush": "Channels heavy dives and ground-slam control.",
    "orbital_dash": "Weaves constant motion and orbiting attacks.",
    "electric_tricks": "Manipulates electric hazards for utility and damage.",
    "tech_interface": "Excels at interfacing with objectives and devices.",
    "phase_shift": "Specialises in phasing through threats and stealth.",
    "stealth_specialist": "Rewards staying unseen until the decisive strike.",
    "weak_interaction": "Uses precision weak-force bursts with positioning demands.",
    "decay_timer": "Operates on timers that must be refreshed or discharged.",
    "berserker": "High risk, high reward close-range powerhouse.",
    "speed_blink": "Relies on instant blinks and relentless tempo.",
    "light_control": "Focuses on beams and high-energy crowd control.",
    "glass_cannon": "Explosive damage with fragile defences—stay mobile.",
    "binding_fields": "Supports allies with protective bonds.",
    "team_link": "Excels when coordinating with allies.",
    "area_pulse": "Dominates zones with heavy area pulses.",
    "mass_boost": "Buffs allies by sharing mass and resilience.",
    "support_aura": "Provides auras that assist the whole team.",
    "rarity_event": "Ultimate ability shines in rare power windows.",
    "reactive_burst": "Explodes in volatile bursts when triggered.",
    "flammable_dash": "Ignites terrain through reckless mobility.",
    "fragile_metal": "Glass cannon metal—strike fast before burning out.",
    "caustic_wash": "Spreads corrosive zones that demand spacing.",
    "poison_lash": "Stacks toxins for damage over time.",
    "radiant_fire": "Burns brightly to blind or bombard foes.",
    "blinding_flare": "Controls vision with intense flashes.",
    "steady_guard": "Bolsters defences to shield allies.",
    "fortify_builder": "Creates fortifications and defensive tools.",
    "weak_interaction": "Uses precise weak-force manipulation to debuff foes.",
    "support": "Provides reliable team-wide buffs.",
    "explosive": "Turns volatility into aggressive plays.",
    "corrosive": "Applies corrosion to soften enemy defences.",
    "heavy_armor": "Stands firm with high durability.",
}

func set_unlock_manager(manager: UnlockManager) -> void:
    _unlock_manager = manager
    _refresh_entries()

func _ready() -> void:
    if _database == null:
        _database = ClassDatabase.new()
    if _unlock_manager == null:
        _unlock_manager = UnlockManager.new()
    if is_instance_valid(_codex_button):
        _codex_button.pressed.connect(_on_codex_button_pressed)
    _configure_tab_titles()
    _refresh_entries()

func _configure_tab_titles() -> void:
    if not is_instance_valid(_tab_container):
        return
    var standard_scroll := _standard_model_list.get_parent()
    if standard_scroll and standard_scroll is Control:
        var idx := _tab_container.get_tab_idx_from_control(standard_scroll)
        if idx >= 0:
            _tab_container.set_tab_title(idx, "Standard Model")
    var element_scroll := _element_list.get_parent()
    if element_scroll and element_scroll is Control:
        var element_idx := _tab_container.get_tab_idx_from_control(element_scroll)
        if element_idx >= 0:
            _tab_container.set_tab_title(element_idx, "Elements")

func _refresh_entries() -> void:
    if not is_instance_valid(_standard_model_list) or not is_instance_valid(_element_list):
        return
    _clear_container(_standard_model_list)
    _clear_container(_element_list)
    if _database == null:
        return
    _populate_category("standard_model", _standard_model_list)
    _populate_category("periodic", _element_list)
    _status_label.text = "Select a particle archetype to begin."

func _clear_container(container: Container) -> void:
    for child in container.get_children():
        child.queue_free()

func _populate_category(category: String, container: VBoxContainer) -> void:
    if container == null:
        return
    var groups := _database.get_category_groups(category)
    groups.sort()
    for group_name in groups:
        container.add_child(_create_category_header(group_name))
        var entries := _database.get_classes_in_group(category, group_name)
        for entry in entries:
            var panel := _create_class_panel(entry)
            container.add_child(panel)

func _create_category_header(category: String) -> Control:
    var label := Label.new()
    label.text = category.capitalize().replace("_", " ")
    label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.85))
    label.add_theme_font_size_override("font_size", 20)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    label.theme_type_variation = "HeaderLarge"
    return label

func _create_class_panel(entry: Dictionary) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.name = String(entry.get("id", ""))
    panel.custom_minimum_size = Vector2(0, 160)
    panel.mouse_filter = Control.MOUSE_FILTER_PASS
    panel.tooltip_text = _build_tooltip(entry)
    var wrapper := VBoxContainer.new()
    wrapper.alignment = BoxContainer.ALIGNMENT_BEGIN
    wrapper.add_theme_constant_override("separation", 6)
    panel.add_child(wrapper)

    var header := HBoxContainer.new()
    header.alignment = BoxContainer.ALIGNMENT_BEGIN
    var title := Label.new()
    title.text = String(entry.get("display_name", "Unknown"))
    title.add_theme_font_size_override("font_size", 18)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    header.add_child(title)

    var select_button := Button.new()
    var unlocked := _unlock_manager.is_class_unlocked(entry)
    select_button.text = unlocked ? "Select" : "Locked"
    select_button.disabled = not unlocked
    select_button.tooltip_text = panel.tooltip_text
    select_button.pressed.connect(_on_class_selected.bind(entry, panel))
    header.add_child(select_button)
    wrapper.add_child(header)

    var lore := Label.new()
    lore.text = String(entry.get("lore", ""))
    lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    wrapper.add_child(lore)

    var stats := entry.get("base_stats", {})
    if typeof(stats) == TYPE_DICTIONARY and not stats.is_empty():
        var stat_grid := GridContainer.new()
        stat_grid.columns = 2
        stat_grid.add_theme_constant_override("h_separation", 16)
        stat_grid.add_theme_constant_override("v_separation", 2)
        var keys := stats.keys()
        keys.sort()
        for key in keys:
            var label_key := Label.new()
            label_key.text = _format_stat_name(String(key)) + ":"
            stat_grid.add_child(label_key)

            var label_value := Label.new()
            label_value.text = _format_stat_value(stats[key])
            label_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
            stat_grid.add_child(label_value)
        wrapper.add_child(stat_grid)

    var playstyle_label := Label.new()
    playstyle_label.text = _build_playstyle_summary(entry)
    playstyle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    wrapper.add_child(playstyle_label)

    if not unlocked:
        var requirement := _unlock_manager.get_unlock_requirement(entry)
        var requirement_label := Label.new()
        requirement_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.4))
        requirement_label.text = _unlock_manager.describe_requirement(requirement)
        requirement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        wrapper.add_child(requirement_label)

    return panel

func _on_class_selected(entry: Dictionary, panel: PanelContainer) -> void:
    _highlight_panel(panel)
    _status_label.text = "Selected: %s" % entry.get("display_name", "Unknown")
    emit_signal("class_chosen", entry.duplicate(true))

func _on_codex_button_pressed() -> void:
    emit_signal("codex_requested")

func _highlight_panel(panel: PanelContainer) -> void:
    if is_instance_valid(_selected_panel):
        _selected_panel.remove_theme_stylebox_override("panel")
    _selected_panel = panel
    if is_instance_valid(_selected_panel):
        var stylebox := StyleBoxFlat.new()
        stylebox.bg_color = Color(0.2, 0.35, 0.5, 0.3)
        stylebox.border_color = Color(0.6, 0.8, 1.0)
        stylebox.border_width_all = 2
        stylebox.corner_radius_all = 4
        _selected_panel.add_theme_stylebox_override("panel", stylebox)

func _build_playstyle_summary(entry: Dictionary) -> String:
    var tags: Array = entry.get("ability_tags", [])
    if tags.is_empty():
        return "Recommended playstyle: Versatile all-rounder."
    var summaries: Array[String] = []
    for tag in tags:
        var key := String(tag)
        if TAG_SUMMARIES.has(key):
            summaries.append(TAG_SUMMARIES[key])
    if summaries.is_empty():
        for tag in tags:
            var readable := String(tag).replace("_", " ")
            readable = readable.substr(0, 1).to_upper() + readable.substr(1)
            summaries.append(readable)
    return "Recommended playstyle: %s" % ". ".join(summaries)

func _format_stat_name(key: String) -> String:
    key = key.replace("_", " ")
    var words := key.split(" ")
    for i in words.size():
        words[i] = words[i].substr(0, 1).to_upper() + words[i].substr(1)
    return " ".join(words)

func _format_stat_value(value) -> String:
    match typeof(value):
        TYPE_FLOAT:
            return "%.3f" % float(value)
        TYPE_INT:
            return str(int(value))
        _:
            return str(value)

func _build_tooltip(entry: Dictionary) -> String:
    var stats := entry.get("base_stats", {})
    var mass_text := "Unknown"
    if typeof(stats) == TYPE_DICTIONARY:
        if stats.has("mass_mev"):
            mass_text = "%s MeV/c²" % _format_stat_value(stats["mass_mev"])
        elif stats.has("atomic_mass"):
            mass_text = "%s u" % _format_stat_value(stats["atomic_mass"])
    var charge_value = 0.0
    var has_charge := false
    if typeof(stats) == TYPE_DICTIONARY and stats.has("charge"):
        charge_value = float(stats["charge"])
        has_charge = true
    var charge_text := has_charge ? _format_charge(charge_value) : "Neutral"
    var spin_text := "N/A"
    if typeof(stats) == TYPE_DICTIONARY and stats.has("spin"):
        spin_text = _format_stat_value(stats["spin"])
    var flavor := String(entry.get("lore", ""))
    var lines := []
    lines.append("Mass: %s" % mass_text)
    lines.append("Charge: %s" % charge_text)
    lines.append("Spin: %s" % spin_text)
    if not flavor.is_empty():
        lines.append("")
        lines.append(flavor)
    var codex_notes := _collect_codex_notes(entry)
    if not codex_notes.is_empty():
        lines.append("")
        lines.append("Codex Notes:")
        for note in codex_notes:
            lines.append("• %s" % note)
    return "\n".join(lines)

func _format_charge(value: float) -> String:
    if is_equal_approx(value, 0.0):
        return "0"
    if value > 0.0:
        return "+%s" % _format_stat_value(value)
    return _format_stat_value(value)

func _collect_codex_notes(entry: Dictionary) -> Array:
    var notes: Array = []
    var class_id := String(entry.get("id", ""))
    if not class_id.is_empty():
        notes.append_array(CodexService.highlights_for_class(class_id))
    var category := String(entry.get("category", ""))
    var group := String(entry.get("group", ""))
    if not category.is_empty() and not group.is_empty():
        notes.append_array(CodexService.highlights_for_group(category, group))
    var unique: Array = []
    for raw_note in notes:
        var text := String(raw_note)
        if text.is_empty():
            continue
        if text in unique:
            continue
        unique.append(text)
    return unique
