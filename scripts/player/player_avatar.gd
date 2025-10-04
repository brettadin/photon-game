extends CharacterBody2D
class_name PlayerAvatar

signal class_changed(new_class)
signal ability_triggered(slot_name, ability: ParticleAbility, details: Dictionary)

@export var base_stats := {
    "speed": 220.0,
    "damage": 1.0,
    "defense": 1.0,
    "shield": 0.0,
    "stealth": 0.0,
    "evasion": 0.0,
    "control": 1.0,
}
@export var base_keywords: Array[StringName] = []

@export var particle_class: ParticleClassDefinition = null setget set_particle_class
var current_stats: Dictionary = {}
var current_keywords: Array[StringName] = []
var mass: float = 1.0
var charge: float = 0.0
var stability: float = 1.0

var _abilities := {}
var _profiles := {}
var _profile_sources := {}
var _profile_uid := 0

func _ready() -> void:
    _recalculate_stats()
    if particle_class:
        var initial := particle_class
        particle_class = null
        set_particle_class(initial)

func set_particle_class(value: ParticleClassDefinition) -> void:
    if value == particle_class:
        return
    _clear_abilities()
    particle_class = value
    if particle_class:
        mass = particle_class.mass
        charge = particle_class.charge
        stability = particle_class.stability
        var loadout := particle_class.create_loadout()
        for slot in loadout:
            _set_ability(slot, loadout[slot])
    else:
        mass = 1.0
        charge = 0.0
        stability = 1.0
    emit_signal("class_changed", particle_class)

func _set_ability(slot: StringName, ability: ParticleAbility) -> void:
    if _abilities.has(slot) and _abilities[slot]:
        var old: ParticleAbility = _abilities[slot]
        old.on_unequip(self)
    _abilities[slot] = ability
    if ability:
        ability.slot = slot
        ability.on_equip(self)

func _clear_abilities() -> void:
    for slot in _abilities:
        var ability: ParticleAbility = _abilities[slot]
        if ability:
            ability.on_unequip(self)
    _abilities.clear()
    remove_stat_profile(null)

func use_ability(slot: StringName, context: Dictionary = {}) -> Dictionary:
    if not _abilities.has(slot):
        return {}
    var ability: ParticleAbility = _abilities[slot]
    if ability == null:
        return {}
    var details := ability.activate(self, context)
    emit_signal("ability_triggered", slot, ability, details)
    return details

func use_active(context: Dictionary = {}) -> Dictionary:
    return use_ability(&"active", context)

func use_passive_refresh(context: Dictionary = {}) -> Dictionary:
    return use_ability(&"passive", context)

func use_ultimate(context: Dictionary = {}) -> Dictionary:
    return use_ability(&"ultimate", context)

func apply_stat_profile(source, profile: Dictionary) -> void:
    var key := _profile_key(source)
    _profiles[key] = _normalize_profile(profile)
    _profile_sources[key] = source
    _recalculate_stats()

func apply_temporary_profile(source, profile: Dictionary, duration: float) -> void:
    _profile_uid += 1
    var key := _profile_key(source, "_temp_%d" % _profile_uid)
    _profiles[key] = _normalize_profile(profile)
    _profile_sources[key] = source
    _recalculate_stats()
    var timer := Timer.new()
    timer.one_shot = true
    timer.wait_time = max(duration, 0.0)
    add_child(timer)
    timer.timeout.connect(_on_temporary_profile_timeout.bind(key, timer))
    timer.start()

func _on_temporary_profile_timeout(key: StringName, timer: Timer) -> void:
    _remove_profile_by_key(key)
    timer.queue_free()

func remove_stat_profile(source) -> void:
    var removal_keys: Array[StringName] = []
    for key in _profile_sources.keys():
        if source == null or _profile_sources[key] == source:
            removal_keys.append(key)
    for key in removal_keys:
        _remove_profile_by_key(key)

func _remove_profile_by_key(key: StringName) -> void:
    _profiles.erase(key)
    _profile_sources.erase(key)
    _recalculate_stats()

func _profile_key(source, suffix: String = "") -> StringName:
    if source == null:
        return StringName("global%s" % suffix)
    return StringName("%s%s" % [str(source.get_instance_id()), suffix])

func _normalize_profile(profile: Dictionary) -> Dictionary:
    var result := {
        "bonuses": {},
        "multipliers": {},
        "keywords": [],
    }
    for key in profile.keys():
        if result.has(key):
            var value = profile[key]
            if value is Dictionary:
                result[key] = value.duplicate(true)
            elif value is Array:
                result[key] = value.duplicate()
            else:
                result[key] = value
    return result

func _recalculate_stats() -> void:
    current_stats = base_stats.duplicate(true)
    current_keywords = base_keywords.duplicate()
    for profile in _profiles.values():
        var bonuses: Dictionary = profile.get("bonuses", {})
        for stat in bonuses.keys():
            current_stats[stat] = current_stats.get(stat, 0.0) + bonuses[stat]
        var multipliers: Dictionary = profile.get("multipliers", {})
        for stat in multipliers.keys():
            current_stats[stat] = current_stats.get(stat, 0.0) * multipliers[stat]
        var keywords: Array = profile.get("keywords", [])
        for keyword in keywords:
            if keyword not in current_keywords:
                current_keywords.append(keyword)

func get_stat(stat: StringName) -> float:
    return current_stats.get(stat, 0.0)

func has_keyword(keyword: StringName) -> bool:
    return keyword in current_keywords
