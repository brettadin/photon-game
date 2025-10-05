extends Control
class_name CharacterSelect

const ClassDatabase := preload("res://scripts/data/class_database.gd")
const UnlockManager := preload("res://scripts/progression/unlock_manager.gd")

signal class_chosen(class_data: Dictionary)

@onready var _class_list: VBoxContainer = %ClassList
@onready var _status_label: Label = %StatusLabel

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
    _refresh_entries()

func _refresh_entries() -> void:
    if not is_instance_valid(_class_list):
        return
    for child in _class_list.get_children():
        child.queue_free()
    if _database == null:
        return
    var categories := _database.get_categories()
    categories.sort()
    for category in categories:
        _class_list.add_child(_create_category_header(category))
        var entries := _database.get_classes_in_category(category)
        for entry in entries:
            var panel := _create_class_panel(entry)
            _class_list.add_child(panel)
    _status_label.text = "Select a particle archetype to begin."

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
