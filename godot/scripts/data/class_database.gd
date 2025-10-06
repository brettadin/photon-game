extends Node
class_name ClassDatabase

const DATA_PATH := "res://data/classes/classes.json"
const STANDARD_MODEL_GROUPS := PackedStringArray(["quarks", "leptons", "bosons"])
const PERIODIC_GROUPS := PackedStringArray([
    "alkali_metals",
    "alkaline_earth_metals",
    "chalcogens",
    "halogens",
    "noble_gases",
    "transition_metals",
    "radioactive_metals",
])

var _entries_by_id: Dictionary = {}
var _entries_by_category: Dictionary = {}
var _entries_by_group: Dictionary = {}

func _init() -> void:
    load_data()

func load_data() -> void:
    var file := FileAccess.open(DATA_PATH, FileAccess.READ)
    if file == null:
        push_error("ClassDatabase: Unable to open data file %s" % DATA_PATH)
        return
    var text := file.get_as_text()
    file.close()
    var parsed := JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("ClassDatabase: Data root must be a dictionary")
        return
    _entries_by_id.clear()
    _entries_by_category.clear()
    _entries_by_group.clear()
    for category in parsed.keys():
        var group_dict = parsed[category]
        if typeof(group_dict) != TYPE_DICTIONARY:
            push_warning("ClassDatabase: Category %s is not a dictionary" % category)
            continue
        _entries_by_category[category] = []
        _entries_by_group[category] = {}
        var expected_groups := _get_expected_groups(category)
        for group_name in group_dict.keys():
            var entries = group_dict[group_name]
            if typeof(entries) != TYPE_ARRAY:
                push_warning("ClassDatabase: Group %s/%s is not an array" % [category, group_name])
                continue
            _entries_by_group[category][group_name] = []
            if expected_groups.size() > 0 and not expected_groups.has(group_name):
                push_warning("ClassDatabase: Group %s unexpected for category %s" % [group_name, category])
            for entry in entries:
                if typeof(entry) != TYPE_DICTIONARY:
                    push_warning("ClassDatabase: Entry in %s/%s is not a dictionary" % [category, group_name])
                    continue
                var id: String = entry.get("id", "")
                if id.is_empty():
                    push_warning("ClassDatabase: Entry missing id in %s/%s" % [category, group_name])
                    continue
                var enriched := entry.duplicate(true)
                enriched["category"] = category
                enriched["group"] = group_name
                _entries_by_id[id] = enriched
                _entries_by_category[category].append(enriched)
                _entries_by_group[category][group_name].append(enriched)
        if expected_groups.size() > 0:
            for missing in expected_groups:
                if not _entries_by_group[category].has(missing):
                    _entries_by_group[category][missing] = []

func get_categories() -> PackedStringArray:
    var categories := PackedStringArray()
    for category in _entries_by_category.keys():
        categories.append(String(category))
    return categories

func get_category_groups(category: String) -> PackedStringArray:
    if not _entries_by_group.has(category):
        return PackedStringArray()
    var groups := PackedStringArray()
    for group_name in _entries_by_group[category].keys():
        groups.append(String(group_name))
    return groups

func get_classes_in_category(category: String) -> Array:
    return _entries_by_category.get(category, []).duplicate()

func get_classes_in_group(category: String, group_name: String) -> Array:
    if not _entries_by_group.has(category):
        return []
    return _entries_by_group[category].get(group_name, []).duplicate()

func get_class_ids() -> PackedStringArray:
    var ids := PackedStringArray()
    for id in _entries_by_id.keys():
        ids.append(String(id))
    return ids

func has_class(id: String) -> bool:
    return _entries_by_id.has(id)

func get_class(id: String) -> Dictionary:
    if not _entries_by_id.has(id):
        return {}
    return _entries_by_id[id].duplicate(true)

func get_group_tags(category: String, group_name: String) -> PackedStringArray:
    var tag_set: Dictionary = {}
    for entry in get_classes_in_group(category, group_name):
        var tags: Array = entry.get("ability_tags", [])
        for tag in tags:
            tag_set[String(tag)] = true
    var packed := PackedStringArray()
    for tag in tag_set.keys():
        packed.append(String(tag))
    return packed

func get_expected_groups_for_category(category: String) -> PackedStringArray:
    return _get_expected_groups(category)

func _get_expected_groups(category: String) -> PackedStringArray:
    match category:
        "standard_model":
            return STANDARD_MODEL_GROUPS
        "periodic":
            return PERIODIC_GROUPS
        _:
            return PackedStringArray()
