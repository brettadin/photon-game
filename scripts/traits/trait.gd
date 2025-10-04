extends Resource
class_name Trait

## Base class for particle traits that can modify stats or inject passive
## gameplay hooks. Traits are designed to be stateless singletons that mutate a
## passed in dictionary to support deterministic stacking behaviour.

@export var id: StringName = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

func apply(stats: Dictionary, context: Dictionary = {}) -> Dictionary:
    ## Default implementation returns the stats unchanged.
    return stats

func get_keywords() -> Array[StringName]:
    return []

func stacks_with(other_id: StringName) -> bool:
    ## By default traits stack with everything including duplicates.
    return true
