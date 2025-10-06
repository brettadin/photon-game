extends Control
class_name CodexViewer

const CodexService := preload("res://scripts/data/codex_service.gd")
const CodexContext := preload("res://scripts/data/codex_context.gd")
const CodexDatabase := preload("res://scripts/data/codex_database.gd")
const UnlockManager := preload("res://scripts/progression/unlock_manager.gd")

signal close_requested(resume_on_close: bool)

@onready var _entry_list: ItemList = %EntryList
@onready var _title_label: Label = %EntryTitle
@onready var _tags_label: Label = %TagsLabel
@onready var _highlight_label: Label = %HighlightLabel
@onready var _body_label: RichTextLabel = %EntryBody
@onready var _status_label: Label = %StatusLabel
@onready var _close_button: Button = %CloseButton
@onready var _ability_section: VBoxContainer = %AbilitySection
@onready var _hazard_section: VBoxContainer = %HazardSection
@onready var _ability_links: FlowContainer = %AbilityLinks
@onready var _hazard_links: FlowContainer = %HazardLinks
@onready var _link_detail_panel: PanelContainer = %LinkDetailPanel
@onready var _link_detail_title: Label = %LinkDetailTitle
@onready var _link_detail_body: RichTextLabel = %LinkDetailBody
@onready var _link_detail_highlights: Label = %LinkDetailHighlights
@onready var _link_detail_close: Button = %LinkDetailClose

var _unlock_manager: UnlockManager
var _resume_on_close: bool = false
var _displayed_entry_id: String = ""

func _ready() -> void:
    if is_instance_valid(_close_button):
        _close_button.pressed.connect(_on_close_pressed)
    if is_instance_valid(_entry_list):
        _entry_list.item_selected.connect(_on_entry_selected)
    if is_instance_valid(_link_detail_close):
        _link_detail_close.pressed.connect(_clear_link_detail)
    _clear_link_detail()
    refresh_entries()

func set_unlock_manager(manager: UnlockManager) -> void:
    _unlock_manager = manager
    refresh_entries()

func set_resume_on_close(resume: bool) -> void:
    _resume_on_close = resume
    if is_instance_valid(_close_button):
        _close_button.text = resume ? "Resume" : "Close"

func show_codex() -> void:
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    visible = true
    refresh_entries()
    _focus_default()

func hide_codex() -> void:
    visible = false

func refresh_entries() -> void:
    var database := CodexService.get_database(true)
    if database == null or not is_instance_valid(_entry_list):
        return
    _entry_list.clear()
    var unlocked_ids: Array = []
    if _unlock_manager != null:
        unlocked_ids = _unlock_manager.get_unlocked_codex_entries()
    var sorted_ids := database.get_sorted_entry_ids()
    for id in sorted_ids:
        var entry := database.get_entry(id)
        var unlocked := unlocked_ids.has(id)
        var item_text := String(entry.get("title", id))
        if not unlocked:
            item_text += " (Locked)"
        _entry_list.add_item(item_text)
        var index := _entry_list.get_item_count() - 1
        _entry_list.set_item_metadata(index, id)
        _entry_list.set_item_disabled(index, not unlocked)
    if sorted_ids.is_empty():
        _status_label.text = "Codex entries unlock as you discover new particle families."
        _clear_entry_display()
    else:
        if _displayed_entry_id.is_empty():
            _select_first_unlocked(database, unlocked_ids)
        else:
            _select_entry(_displayed_entry_id)

func show_entry(id: String) -> void:
    _displayed_entry_id = id
    _select_entry(id)

func _select_first_unlocked(database: CodexDatabase, unlocked_ids: Array) -> void:
    var sorted_ids := database.get_sorted_entry_ids()
    for id in sorted_ids:
        if unlocked_ids.has(id):
            _select_entry(id)
            return
    if not sorted_ids.is_empty():
        _select_entry(sorted_ids[0])

func _select_entry(id: String) -> void:
    if not is_instance_valid(_entry_list):
        return
    var item_count := _entry_list.get_item_count()
    for i in range(item_count):
        if _entry_list.get_item_metadata(i) == id:
            _entry_list.select(i)
            _render_entry(id)
            return
    _render_entry(id)

func _render_entry(id: String) -> void:
    var database := CodexService.get_database()
    if database == null:
        return
    var entry := database.get_entry(id)
    if entry.is_empty():
        _status_label.text = "Unlock codex entries by exploring new content."
        _clear_entry_display()
        return
    if _unlock_manager and not _unlock_manager.is_codex_entry_unlocked(id):
        _status_label.text = "Unlock this entry by discovering relevant particles."
        _clear_entry_display()
        return
    _displayed_entry_id = id
    _status_label.text = ""
    _title_label.text = String(entry.get("title", ""))
    var tags := entry.get("tags", [])
    if typeof(tags) == TYPE_ARRAY and not tags.is_empty():
        var readable := []
        for tag in tags:
            readable.append(String(tag))
        _tags_label.text = "Tags: %s" % ", ".join(readable)
    else:
        _tags_label.text = "Tags: None"
    var highlight := String(entry.get("highlight", ""))
    _highlight_label.visible = not highlight.is_empty()
    _highlight_label.text = highlight
    var body := entry.get("body", "")
    if typeof(body) == TYPE_ARRAY:
        body = "\n\n".join(body)
    _body_label.clear()
    _body_label.append_text(String(body))
    _populate_related_links(entry)
    _clear_link_detail()

func _populate_related_links(entry: Dictionary) -> void:
    _clear_children(_ability_links)
    _clear_children(_hazard_links)
    var links := entry.get("links", {})
    if typeof(links) != TYPE_DICTIONARY:
        links = {}
    var ability_ids: Array = links.get("abilities", []) if typeof(links) == TYPE_DICTIONARY else []
    var hazard_ids: Array = links.get("hazards", []) if typeof(links) == TYPE_DICTIONARY else []
    var ability_count := _populate_link_buttons("ability", ability_ids, _ability_links)
    var hazard_count := _populate_link_buttons("hazard", hazard_ids, _hazard_links)
    _ability_section.visible = ability_count > 0
    _hazard_section.visible = hazard_count > 0

func _populate_link_buttons(subject_type: String, ids: Array, container: Container) -> int:
    if container == null:
        return 0
    var count := 0
    for raw_id in ids:
        var id := String(raw_id)
        if id.is_empty():
            continue
        var button := Button.new()
        button.text = _link_display_name(subject_type, id)
        button.focus_mode = Control.FOCUS_ALL
        button.tooltip_text = _link_tooltip(subject_type, id)
        button.pressed.connect(_on_related_pressed.bind(subject_type, id))
        container.add_child(button)
        count += 1
    return count

func _link_display_name(subject_type: String, id: String) -> String:
    match subject_type:
        "ability":
            var meta := CodexContext.get_ability_metadata(StringName(id))
            return String(meta.get("name", id.capitalize().replace("_", " ")))
        "hazard":
            var hazard := CodexContext.get_hazard_metadata(StringName(id))
            return String(hazard.get("name", id.capitalize().replace("_", " ")))
        _:
            return id.capitalize().replace("_", " ")

func _link_tooltip(subject_type: String, id: String) -> String:
    var notes: Array = []
    match subject_type:
        "ability":
            notes = CodexService.highlights_for_ability(id)
        "hazard":
            notes = CodexService.highlights_for_hazard(id)
        _:
            notes = []
    if notes.is_empty():
        return ""
    return "\n".join(notes)

func _on_related_pressed(subject_type: String, subject_id: String) -> void:
    _show_related_detail(subject_type, subject_id)

func _show_related_detail(subject_type: String, subject_id: String) -> void:
    var highlights: Array = []
    var title := ""
    var body_lines: Array = []
    match subject_type:
        "ability":
            var ability := CodexContext.get_ability_metadata(StringName(subject_id))
            title = String(ability.get("name", subject_id))
            var description := String(ability.get("description", ""))
            if not description.is_empty():
                body_lines.append(description)
            var cooldown := float(ability.get("cooldown", 0.0))
            if cooldown > 0.0:
                body_lines.append("Cooldown: %.1fs" % cooldown)
            var costs := CodexContext.format_costs(ability.get("resource_costs", {}))
            if not costs.is_empty():
                body_lines.append("Costs: %s" % costs)
            highlights = CodexService.highlights_for_ability(subject_id)
        "hazard":
            var hazard := CodexContext.get_hazard_metadata(StringName(subject_id))
            title = String(hazard.get("name", subject_id))
            var description_h := String(hazard.get("description", ""))
            if not description_h.is_empty():
                body_lines.append(description_h)
            var tip := String(hazard.get("tip", ""))
            if not tip.is_empty():
                body_lines.append("Fieldcraft: %s" % tip)
            highlights = CodexService.highlights_for_hazard(subject_id)
        _:
            title = subject_id.capitalize()
            highlights = []
    _link_detail_title.text = title
    _link_detail_body.clear()
    if body_lines.is_empty():
        _link_detail_body.append_text("No additional data recorded.")
    else:
        _link_detail_body.append_text("\n\n".join(body_lines))
    if highlights.is_empty():
        _link_detail_highlights.text = ""
        _link_detail_highlights.visible = false
    else:
        var formatted := []
        for note in highlights:
            formatted.append("• %s" % String(note))
        _link_detail_highlights.text = "Codex notes:\n%s" % "\n".join(formatted)
        _link_detail_highlights.visible = true
    _link_detail_panel.visible = true

func _clear_entry_display() -> void:
    _title_label.text = ""
    _tags_label.text = "Tags: None"
    _highlight_label.text = ""
    _highlight_label.visible = false
    _body_label.clear()
    _ability_section.visible = false
    _hazard_section.visible = false
    _clear_link_detail()

func _clear_children(node: Node) -> void:
    if node == null:
        return
    for child in node.get_children():
        child.queue_free()

func _clear_link_detail() -> void:
    if is_instance_valid(_link_detail_panel):
        _link_detail_panel.visible = false
    if is_instance_valid(_link_detail_body):
        _link_detail_body.clear()
    if is_instance_valid(_link_detail_title):
        _link_detail_title.text = ""
    if is_instance_valid(_link_detail_highlights):
        _link_detail_highlights.text = ""
        _link_detail_highlights.visible = false

func _focus_default() -> void:
    if is_instance_valid(_entry_list) and _entry_list.get_item_count() > 0:
        _entry_list.grab_focus()
    elif is_instance_valid(_close_button):
        _close_button.grab_focus()

func _on_entry_selected(index: int) -> void:
    var id := String(_entry_list.get_item_metadata(index))
    _render_entry(id)

func _on_close_pressed() -> void:
    hide_codex()
    emit_signal("close_requested", _resume_on_close)
*** End
