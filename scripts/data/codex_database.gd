extends Node
class_name CodexDatabase

const DATA_DIRECTORY := "res://data/codex_entries"
const ROOT_FILE := "res://data/codex_entries.json"

var _entries: Dictionary = {}
var _entries_by_unlock: Dictionary = {}
var _entries_by_subject: Dictionary = {}

func _init() -> void:
    _load_entries()

func _load_entries() -> void:
    _entries.clear()
    _entries_by_unlock.clear()
    _entries_by_subject.clear()
    if FileAccess.file_exists(ROOT_FILE):
        _load_file(ROOT_FILE)
    var dir := DirAccess.open(DATA_DIRECTORY)
    if dir == null:
        push_warning("CodexDatabase: Unable to open directory %s" % DATA_DIRECTORY)
        return
    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if file_name.begins_with("."):
            file_name = dir.get_next()
            continue
        if not dir.current_is_dir() and file_name.ends_with(".json"):
            _load_file("%s/%s" % [DATA_DIRECTORY, file_name])
        file_name = dir.get_next()
    dir.list_dir_end()

func _load_file(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_warning("CodexDatabase: Unable to read %s" % path)
        return
    var text := file.get_as_text()
    file.close()
    var parsed := JSON.parse_string(text)
    if typeof(parsed) == TYPE_DICTIONARY and parsed.has("entries"):
        parsed = parsed["entries"]
    if typeof(parsed) != TYPE_ARRAY:
        push_warning("CodexDatabase: %s does not contain an array of entries" % path)
        return
    for raw_entry in parsed:
        if typeof(raw_entry) != TYPE_DICTIONARY:
            continue
        var id := String(raw_entry.get("id", ""))
        if id.is_empty():
            push_warning("CodexDatabase: Entry without id in %s" % path)
            continue
        var entry := raw_entry.duplicate(true)
        _entries[id] = entry
        _register_unlock(entry)
        _register_subjects(entry)

func _register_unlock(entry: Dictionary) -> void:
    var unlock := entry.get("unlock", {})
    if typeof(unlock) != TYPE_DICTIONARY:
        unlock = {}
    if unlock.is_empty():
        _append_unlock("always", entry)
        return
    var unlock_type := String(unlock.get("type", ""))
    match unlock_type:
        "group":
            var category := String(unlock.get("category", ""))
            var group := String(unlock.get("group", ""))
            if category.is_empty() or group.is_empty():
                push_warning("CodexDatabase: group unlock missing category or group for %s" % entry.get("id", "unknown"))
                return
            _append_unlock("group:%s:%s" % [category, group], entry)
            _append_unlock("category:%s" % category, entry)
        "category":
            var cat := String(unlock.get("category", ""))
            if cat.is_empty():
                push_warning("CodexDatabase: category unlock missing category for %s" % entry.get("id", "unknown"))
                return
            _append_unlock("category:%s" % cat, entry)
        "always":
            _append_unlock("always", entry)
        _:
            push_warning("CodexDatabase: Unknown unlock type %s" % unlock_type)

func _append_unlock(key: String, entry: Dictionary) -> void:
    if key.is_empty():
        return
    if not _entries_by_unlock.has(key):
        _entries_by_unlock[key] = []
    var list: Array = _entries_by_unlock[key]
    if list.has(entry["id"]):
        return
    list.append(entry["id"])
    _entries_by_unlock[key] = list

func _register_subjects(entry: Dictionary) -> void:
    var subjects := entry.get("subjects", {})
    if typeof(subjects) != TYPE_DICTIONARY:
        return
    for raw_type in subjects.keys():
        var values = subjects[raw_type]
        if typeof(values) == TYPE_NIL:
            continue
        var subject_type := String(raw_type)
        var ids: Array = []
        if typeof(values) == TYPE_ARRAY:
            ids = values.duplicate()
        else:
            ids = [values]
        for raw_id in ids:
            var subject_id := String(raw_id)
            if subject_id.is_empty():
                continue
            _append_subject_entry(subject_type, subject_id, String(entry.get("id", "")))

func _append_subject_entry(subject_type: String, subject_id: String, entry_id: String) -> void:
    if subject_type.is_empty() or entry_id.is_empty():
        return
    var canonical_type := _canonical_subject_type(subject_type)
    if canonical_type.is_empty():
        return
    if not _entries_by_subject.has(canonical_type):
        _entries_by_subject[canonical_type] = {}
    var type_bucket: Dictionary = _entries_by_subject[canonical_type]
    if not type_bucket.has(subject_id):
        type_bucket[subject_id] = []
    var entry_list: Array = type_bucket[subject_id]
    if entry_id in entry_list:
        return
    entry_list.append(entry_id)
    type_bucket[subject_id] = entry_list
    _entries_by_subject[canonical_type] = type_bucket

func _canonical_subject_type(raw_type: String) -> String:
    match raw_type:
        "classes", "class":
            return "class"
        "groups", "group":
            return "group"
        "abilities", "ability":
            return "ability"
        "hazards", "hazard":
            return "hazard"
        _:
            return ""

func get_entries() -> Dictionary:
    return _entries.duplicate(true)

func get_entry(id: String) -> Dictionary:
    if not _entries.has(id):
        return {}
    return _entries[id].duplicate(true)

func get_entry_links(id: String) -> Dictionary:
    var entry := get_entry(id)
    if entry.is_empty():
        return {}
    var links := entry.get("links", {})
    if typeof(links) != TYPE_DICTIONARY:
        return {}
    return links.duplicate(true)

func get_entry_highlight(id: String) -> String:
    var entry := get_entry(id)
    if entry.is_empty():
        return ""
    return String(entry.get("highlight", ""))

func get_sorted_entry_ids() -> Array:
    var ids := _entries.keys()
    ids.sort_custom(self, "_compare_entries")
    return ids

func _compare_entries(a, b) -> bool:
    var entry_a := _entries[a]
    var entry_b := _entries[b]
    var category_a := String(entry_a.get("category", ""))
    var category_b := String(entry_b.get("category", ""))
    if category_a == category_b:
        return String(entry_a.get("title", a)) < String(entry_b.get("title", b))
    return category_a < category_b

func entries_for_unlock(category: String, group: String = "") -> Array:
    var result: Array = []
    if _entries_by_unlock.has("always"):
        result.append_array(_entries_by_unlock["always"])
    if not category.is_empty():
        var cat_key := "category:%s" % category
        if _entries_by_unlock.has(cat_key):
            result.append_array(_entries_by_unlock[cat_key])
        if not group.is_empty():
            var group_key := "group:%s:%s" % [category, group]
            if _entries_by_unlock.has(group_key):
                result.append_array(_entries_by_unlock[group_key])
    var unique := []
    for id in result:
        if not unique.has(id):
            unique.append(id)
    return unique

func get_entries_for_subject(subject_type: String, subject_id: String) -> Array:
    var canonical_type := _canonical_subject_type(subject_type)
    if canonical_type.is_empty():
        return []
    if not _entries_by_subject.has(canonical_type):
        return []
    var bucket: Dictionary = _entries_by_subject[canonical_type]
    if not bucket.has(subject_id):
        return []
    return bucket[subject_id].duplicate()

func get_highlights_for_subject(subject_type: String, subject_id: String) -> Array:
    var ids := get_entries_for_subject(subject_type, subject_id)
    var highlights: Array = []
    for id in ids:
        var highlight := get_entry_highlight(String(id))
        if highlight.is_empty():
            continue
        if highlight in highlights:
            continue
        highlights.append(highlight)
    return highlights

func get_highlights_for_class(class_id: String) -> Array:
    return get_highlights_for_subject("class", class_id)

func get_highlights_for_group(category: String, group: String) -> Array:
    var id := "%s/%s" % [category, group]
    return get_highlights_for_subject("group", id)

func get_highlights_for_ability(ability_id: String) -> Array:
    return get_highlights_for_subject("ability", ability_id)

func get_highlights_for_hazard(hazard_id: String) -> Array:
    return get_highlights_for_subject("hazard", hazard_id)
