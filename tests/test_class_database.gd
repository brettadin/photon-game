extends GutTest

var _db: ClassDatabase

func before_all() -> void:
    _db = ClassDatabase.new()
    _db.load_data()

func test_all_entries_have_required_fields() -> void:
    var required_fields := ["display_name", "lore", "base_stats", "ability_tags"]
    for class_id in _db.get_class_ids():
        var entry := _db.get_class(class_id)
        assert_true(entry.size() > 0, "Expected data for %s" % class_id)
        for field in required_fields:
            assert_true(entry.has(field), "%s missing %s" % [class_id, field])
        var stats := entry.get("base_stats", null)
        assert_true(stats is Dictionary, "%s base_stats should be a dictionary" % class_id)
        assert_true(stats.has("charge"), "%s base stats missing charge" % class_id)
        assert_true(stats.has("stability"), "%s base stats missing stability" % class_id)
        assert_true(
            stats.has("mass_mev") or stats.has("atomic_mass"),
            "%s base stats missing mass field" % class_id
        )
        var ability_tags := entry.get("ability_tags", [])
        assert_true(ability_tags is Array and ability_tags.size() > 0, "%s requires at least one ability tag" % class_id)

func test_standard_model_groups_populated() -> void:
    var expected := _db.get_expected_groups_for_category("standard_model")
    for group_name in expected:
        var entries := _db.get_classes_in_group("standard_model", group_name)
        assert_true(entries.size() > 0, "Expected members in standard model group %s" % group_name)

func test_noble_gases_share_support_tag() -> void:
    var noble_gases := _db.get_classes_in_group("periodic", "noble_gases")
    assert_true(noble_gases.size() >= 3, "Expected at least three noble gas entries")
    for entry in noble_gases:
        var tags: Array = entry.get("ability_tags", [])
        assert_true(tags.has("support_inert"), "%s should include support_inert tag" % entry.get("id", entry.get("display_name")))

func test_alkali_metals_are_reactive() -> void:
    var alkali := _db.get_classes_in_group("periodic", "alkali_metals")
    assert_true(alkali.size() >= 2, "Expected at least two alkali metals")
    for entry in alkali:
        var stats := entry.get("base_stats", {})
        assert_true(stats.get("reactivity", 0.0) >= 0.9, "%s should have high reactivity" % entry.get("id", entry.get("display_name")))
        var tags: Array = entry.get("ability_tags", [])
        assert_true(tags.has("reactive_burst"), "%s should include reactive_burst tag" % entry.get("id", entry.get("display_name")))
