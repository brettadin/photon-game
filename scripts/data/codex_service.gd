extends Object
class_name CodexService

const CodexDatabase := preload("res://scripts/data/codex_database.gd")

static var _database: CodexDatabase = null

static func get_database(refresh: bool = false) -> CodexDatabase:
    if refresh or _database == null:
        _database = CodexDatabase.new()
    return _database

static func highlights_for_class(class_id: String) -> Array:
    if class_id.is_empty():
        return []
    return get_database().get_highlights_for_class(class_id)

static func highlights_for_group(category: String, group: String) -> Array:
    if category.is_empty() or group.is_empty():
        return []
    return get_database().get_highlights_for_group(category, group)

static func highlights_for_ability(ability_id: String) -> Array:
    if ability_id.is_empty():
        return []
    return get_database().get_highlights_for_ability(ability_id)

static func highlights_for_hazard(hazard_id: String) -> Array:
    if hazard_id.is_empty():
        return []
    return get_database().get_highlights_for_hazard(hazard_id)

static func entry(id: String) -> Dictionary:
    if id.is_empty():
        return {}
    return get_database().get_entry(id)

static func entry_links(id: String) -> Dictionary:
    if id.is_empty():
        return {}
    return get_database().get_entry_links(id)

static func entry_highlight(id: String) -> String:
    if id.is_empty():
        return ""
    return get_database().get_entry_highlight(id)

static func entries_for_subject(subject_type: String, subject_id: String) -> Array:
    if subject_type.is_empty() or subject_id.is_empty():
        return []
    return get_database().get_entries_for_subject(subject_type, subject_id)
