extends Resource
class_name ParticleClassDefinition

## Defines a playable particle archetype with physics-flavoured stats
## and hooks to the abilities that drive its behaviour.
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

## Core physical properties highlighted for flavour/gameplay.
@export var mass: float = 1.0
@export var charge: float = 0.0
@export var stability: float = 1.0

## Ability slots. The exported scripts must extend ParticleAbility.
@export var active_ability: Script
@export var passive_ability: Script
@export var ultimate_ability: Script
@export var class_tags: Array[StringName] = []

func _instantiate_ability(script: Script) -> ParticleAbility:
    if script == null:
        return null
    var ability := script.new()
    if ability is ParticleAbility:
        return ability
    push_warning("%s does not extend ParticleAbility" % script.resource_path)
    return null

func create_loadout() -> Dictionary:
    return {
        "active": _instantiate_ability(active_ability),
        "passive": _instantiate_ability(passive_ability),
        "ultimate": _instantiate_ability(ultimate_ability),
    }

func get_summary() -> String:
    return "%s (q=%0.2f, m=%0.3f, stability=%0.2f)" % [display_name, charge, mass, stability]
