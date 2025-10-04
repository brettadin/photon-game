extends Resource
class_name ParticleClass

## Resource defining a particle archetype with optional element group affinities.
## Supports group-wide stat modifiers and trait bundles that can stack with
## class-specific abilities. Designed for Godot 4.x.

@export var display_name: String = ""
@export_multiline var description: String = ""

## Enumeration representing elemental behaviour sets.
enum ElementGroup {
    NONE,
    ALKALI,
    ALKALINE_EARTH,
    CHALCOGEN,
    HALOGEN,
    NOBLE_GAS,
    TRANSITION,
    RADIOACTIVE,
}

@export var element_group: ElementGroup = ElementGroup.NONE setget set_element_group

## Baseline stats supplied by the particle class itself.
@export var base_reactivity: float = 1.0
@export var base_defense: float = 1.0

## Optional class specific trait scripts (Script resources that extend Trait).
@export var class_trait_scripts: Array[Script] = []

## Optional override for group trait scripts. If empty we fall back to the
## defaults registered in [code]GROUP_TRAIT_SCRIPTS[/code].
@export var group_trait_scripts: Array[Script] = []

## Additional keywords used to tag playstyle hooks (e.g. "explosive").
@export var keywords: Array[StringName] = []

const DEFAULT_GROUP_MODIFIER := {
    "reactivity_multiplier": 1.0,
    "defense_multiplier": 1.0,
    "keywords": [],
}

const GROUP_MODIFIERS := {
    ElementGroup.ALKALI: {
        "reactivity_multiplier": 1.35,
        "defense_multiplier": 0.85,
        "keywords": ["explosive"],
    },
    ElementGroup.ALKALINE_EARTH: {
        "reactivity_multiplier": 1.1,
        "defense_multiplier": 1.1,
        "keywords": ["support"],
    },
    ElementGroup.CHALCOGEN: {
        "reactivity_multiplier": 1.2,
        "defense_multiplier": 0.95,
        "keywords": ["corrosive"],
    },
    ElementGroup.HALOGEN: {
        "reactivity_multiplier": 1.3,
        "defense_multiplier": 0.9,
        "keywords": ["corrosive"],
    },
    ElementGroup.NOBLE_GAS: {
        "reactivity_multiplier": 0.9,
        "defense_multiplier": 1.3,
        "keywords": ["support"],
    },
    ElementGroup.TRANSITION: {
        "reactivity_multiplier": 1.05,
        "defense_multiplier": 1.35,
        "keywords": ["heavy_armor"],
    },
    ElementGroup.RADIOACTIVE: {
        "reactivity_multiplier": 1.4,
        "defense_multiplier": 0.95,
        "keywords": ["explosive", "corrosive"],
    },
}

const GROUP_TRAIT_SCRIPTS := {
    ElementGroup.ALKALI: [
        preload("res://scripts/traits/alkali_overload.gd"),
    ],
    ElementGroup.ALKALINE_EARTH: [
        preload("res://scripts/traits/alkaline_reservoir.gd"),
    ],
    ElementGroup.CHALCOGEN: [
        preload("res://scripts/traits/chalcogen_corrosion.gd"),
    ],
    ElementGroup.HALOGEN: [
        preload("res://scripts/traits/halogen_etching.gd"),
    ],
    ElementGroup.NOBLE_GAS: [
        preload("res://scripts/traits/noble_shield.gd"),
    ],
    ElementGroup.TRANSITION: [
        preload("res://scripts/traits/transition_plating.gd"),
    ],
    ElementGroup.RADIOACTIVE: [
        preload("res://scripts/traits/radioactive_meltdown.gd"),
    ],
}

func set_element_group(value: ElementGroup) -> void:
    element_group = value
    # When the group changes we clear any previously assigned overrides so the
    # new default perks are used unless explicitly overridden again.
    if group_trait_scripts.is_empty():
        return
    group_trait_scripts.clear()

func get_group_modifiers() -> Dictionary:
    return GROUP_MODIFIERS.get(element_group, DEFAULT_GROUP_MODIFIER)

func get_group_keywords() -> Array[StringName]:
    var result: Array[StringName] = []
    for keyword in keywords:
        if keyword not in result:
            result.append(keyword)
    var group_data := get_group_modifiers()
    for keyword in group_data.get("keywords", []):
        if keyword not in result:
            result.append(keyword)
    return result

func get_default_group_trait_scripts() -> Array[Script]:
    return GROUP_TRAIT_SCRIPTS.get(element_group, [])

func get_all_trait_scripts(extra_traits: Array[Script] = []) -> Array[Script]:
    var scripts: Array[Script] = []
    scripts.append_array(class_trait_scripts)
    if group_trait_scripts.is_empty():
        scripts.append_array(get_default_group_trait_scripts())
    else:
        scripts.append_array(group_trait_scripts)
    scripts.append_array(extra_traits)
    return scripts

func get_effective_stats(extra_traits: Array[Script] = [], context: Dictionary = {}) -> Dictionary:
    var modifiers := get_group_modifiers()
    var stats := {
        "reactivity": base_reactivity * modifiers.get("reactivity_multiplier", 1.0),
        "defense": base_defense * modifiers.get("defense_multiplier", 1.0),
        "keywords": get_group_keywords(),
    }

    for trait_script in get_all_trait_scripts(extra_traits):
        if trait_script == null:
            continue
        var trait := trait_script.new()
        if not trait:
            continue
        if not trait.has_method("apply"):
            push_warning("Trait %s is missing an apply() method" % [trait_script.resource_path])
            continue
        stats = trait.apply(stats, context)
    return stats

func describe() -> String:
    var modifiers := get_group_modifiers()
    var lines := []
    lines.append("Group: %s" % ElementGroup.keys()[element_group])
    lines.append("Base Reactivity: %.2f (x%.2f group)" % [base_reactivity, modifiers.get("reactivity_multiplier", 1.0)])
    lines.append("Base Defense: %.2f (x%.2f group)" % [base_defense, modifiers.get("defense_multiplier", 1.0)])
    if not keywords.is_empty():
        lines.append("Class Keywords: %s" % ", ".join(keywords))
    var group_keywords := get_group_keywords()
    if not group_keywords.is_empty():
        lines.append("Group Keywords: %s" % ", ".join(group_keywords))
    return "\n".join(lines)
