extends CharacterBody2D
class_name PlayerAvatar

const StatusManager := preload("res://scripts/combat/status_manager.gd")
const LEPTON_IDS := {
    StringName("electron"): true,
    StringName("electron_neutrino"): true,
}

signal class_changed(new_class)
signal ability_triggered(slot_name, ability: ParticleAbility, details: Dictionary)
signal resource_changed(resource_name: StringName, current: float, maximum: float)
signal self_damage_taken(amount: float, payload: Dictionary)

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

var resource_pools: Dictionary = {}
var status_manager: StatusManager = null

var _abilities := {}
var _profiles := {}
var _profile_sources := {}
var _profile_uid := 0

func _enter_tree() -> void:
    _ensure_status_manager()

func _ready() -> void:
    _recalculate_stats()
    _initialize_resources()
    _update_instability_factor()
    if particle_class:
        var initial := particle_class
        particle_class = null
        set_particle_class(initial)

func set_particle_class(value: ParticleClassDefinition) -> void:
    _ensure_status_manager()
    if value == particle_class:
        return
    _clear_abilities()
    particle_class = value
    if particle_class:
        mass = particle_class.mass
        charge = particle_class.charge
        stability = particle_class.stability
        _initialize_resources()
        var loadout := particle_class.create_loadout()
        for slot in loadout:
            _set_ability(slot, loadout[slot])
    else:
        mass = 1.0
        charge = 0.0
        stability = 1.0
        _initialize_resources()
    _update_instability_factor()
    _update_status_immunities()
    emit_signal("class_changed", particle_class)

func get_status_manager() -> StatusManager:
    return status_manager

func set_resource(name: StringName, current: float, maximum: float) -> void:
    name = StringName(name)
    maximum = max(maximum, 0.0)
    var pool := {
        "current": clamp(current, 0.0, maximum if maximum > 0.0 else current),
        "max": maximum,
    }
    if maximum <= 0.0:
        pool["current"] = max(current, 0.0)
    resource_pools[name] = pool
    emit_signal("resource_changed", name, pool["current"], pool["max"])
    if name == &"stability":
        _update_instability_factor()

func modify_resource(name: StringName, delta: float) -> void:
    name = StringName(name)
    var pool: Dictionary = resource_pools.get(name, {})
    var max_amount := float(pool.get("max", 0.0))
    var current := float(pool.get("current", 0.0)) + delta
    if max_amount > 0.0:
        current = clamp(current, 0.0, max_amount)
    else:
        current = max(current, 0.0)
        max_amount = max(max_amount, current)
    pool["current"] = current
    pool["max"] = max_amount
    resource_pools[name] = pool
    emit_signal("resource_changed", name, current, max_amount)
    if name == &"stability":
        _update_instability_factor()

func get_resource_amount(name: StringName) -> float:
    name = StringName(name)
    var pool: Dictionary = resource_pools.get(name, {})
    return float(pool.get("current", 0.0))

func get_resource_capacity(name: StringName) -> float:
    name = StringName(name)
    var pool: Dictionary = resource_pools.get(name, {})
    return float(pool.get("max", 0.0))

func has_resources(costs: Dictionary) -> bool:
    for name in costs.keys():
        if get_resource_amount(StringName(name)) + 0.0001 < float(costs[name]):
            return false
    return true

func get_missing_resources(costs: Dictionary) -> Dictionary:
    var missing := {}
    for name in costs.keys():
        var required := float(costs[name])
        var available := get_resource_amount(StringName(name))
        if available + 0.0001 < required:
            missing[name] = required - available
    return missing

func apply_resource_costs(costs: Dictionary) -> bool:
    if not has_resources(costs):
        return false
    for name in costs.keys():
        modify_resource(StringName(name), -float(costs[name]))
    return true

func restore_resource(name: StringName, amount: float) -> void:
    name = StringName(name)
    if amount <= 0.0:
        return
    modify_resource(name, amount)

func apply_self_damage(payload: Dictionary) -> void:
    var amount := float(payload.get("amount", 0.0))
    if amount <= 0.0:
        return
    modify_resource(&"stability", -amount)
    emit_signal("self_damage_taken", amount, payload)

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
    if status_manager:
        status_manager.clear_all_statuses()

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

func _ensure_status_manager() -> void:
    if status_manager:
        return
    status_manager = StatusManager.new()
    status_manager.name = "StatusManager"
    status_manager.host = self
    add_child(status_manager)
    _update_status_immunities()

func _initialize_resources() -> void:
    resource_pools.clear()
    set_resource(&"energy", 100.0, 100.0)
    var stability_capacity := max(stability, 0.0) * 100.0
    if stability_capacity <= 0.0:
        stability_capacity = 1.0
    set_resource(&"stability", stability_capacity, stability_capacity)

func _update_instability_factor() -> void:
    if status_manager == null:
        return
    var baseline := clamp(1.0 - stability, 0.0, 1.0)
    var stability_pool: Dictionary = resource_pools.get(&"stability", {})
    var max_amount := float(stability_pool.get("max", 0.0))
    if max_amount > 0.0:
        var ratio := float(stability_pool.get("current", max_amount)) / max_amount
        baseline = max(baseline, 1.0 - ratio)
    status_manager.set_instability_factor(baseline)

func _update_status_immunities() -> void:
    if status_manager == null:
        return
    status_manager.clear_immunities()
    if particle_class and LEPTON_IDS.has(particle_class.id):
        status_manager.set_immunity(&"strong_force", true)
