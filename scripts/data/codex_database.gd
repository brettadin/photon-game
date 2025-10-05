extends Node
class_name CodexDatabase

const DATA_DIRECTORY := "res://data/codex_entries"

var _entries: Dictionary = {}
var _entries_by_unlock: Dictionary = {}

func _init() -> void:
    _load_entries()

func _load_entries() -> void:
    _entries.clear()
    _entries_by_unlock.clear()
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

func get_entries() -> Dictionary:
    return _entries.duplicate(true)

func get_entry(id: String) -> Dictionary:
    if not _entries.has(id):
        return {}
    return _entries[id].duplicate(true)

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
