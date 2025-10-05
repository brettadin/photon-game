extends Control
class_name Codex

const CodexDatabase := preload("res://scripts/data/codex_database.gd")
const UnlockManager := preload("res://scripts/progression/unlock_manager.gd")

signal close_requested(resume_on_close: bool)

@onready var _entry_list: ItemList = %EntryList
@onready var _title_label: Label = %EntryTitle
@onready var _body_label: RichTextLabel = %EntryBody
@onready var _tags_label: Label = %TagsLabel
@onready var _status_label: Label = %StatusLabel
@onready var _close_button: Button = %CloseButton

var _database: CodexDatabase
var _unlock_manager: UnlockManager
var _resume_on_close: bool = false
var _displayed_entry_id: String = ""

func _ready() -> void:
    if _database == null:
        _database = CodexDatabase.new()
    if is_instance_valid(_close_button):
        _close_button.pressed.connect(_on_close_pressed)
    if is_instance_valid(_entry_list):
        _entry_list.item_selected.connect(_on_entry_selected)
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
    if _database == null:
        return
    if not is_instance_valid(_entry_list):
        return
    _entry_list.clear()
    var unlocked_ids := []
    if _unlock_manager != null:
        unlocked_ids = _unlock_manager.get_unlocked_codex_entries()
    var sorted_ids := _database.get_sorted_entry_ids()
    for id in sorted_ids:
        var entry := _database.get_entry(id)
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
            _select_first_unlocked()
        else:
            _select_entry(_displayed_entry_id)

func show_entry(id: String) -> void:
    _displayed_entry_id = id
    _select_entry(id)

func _select_first_unlocked() -> void:
    if _database == null:
        return
    var unlocked_ids := []
    if _unlock_manager != null:
        unlocked_ids = _unlock_manager.get_unlocked_codex_entries()
    var sorted_ids := _database.get_sorted_entry_ids()
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
    if _database == null:
        return
    var entry := _database.get_entry(id)
    if entry.is_empty():
        _clear_entry_display()
        return
    if _unlock_manager and not _unlock_manager.is_codex_entry_unlocked(id):
        _status_label.text = "Unlock this entry by discovering relevant particles."
        _clear_entry_display()
        return
    _displayed_entry_id = id
    _title_label.text = String(entry.get("title", ""))
    var tags := entry.get("tags", [])
    if typeof(tags) == TYPE_ARRAY and not tags.is_empty():
        var readable := []
        for tag in tags:
            readable.append(String(tag).capitalize())
        _tags_label.text = "Tags: %s" % ", ".join(readable)
    else:
        _tags_label.text = "Tags: None"
    var body := entry.get("body", "")
    if typeof(body) == TYPE_ARRAY:
        body = "\n\n".join(body)
    _body_label.clear()
    _body_label.append_text(String(body))
    _status_label.text = ""

func _clear_entry_display() -> void:
    _title_label.text = ""
    _tags_label.text = "Tags: None"
    _body_label.clear()

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
