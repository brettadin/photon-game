extends CharacterBody2D
class_name PlayerAvatar

const STATUS_MANAGER_SCRIPT := preload("res://scripts/combat/status_manager.gd")
const ABILITY_CATALOG := preload("res://scripts/abilities/ability_catalog.gd")
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

var _particle_class: ParticleClassDefinition = null

@export var particle_class: ParticleClassDefinition = null:
    set(value):
        set_particle_class(value)
    get:
        return _particle_class
var current_stats: Dictionary = {}
var current_keywords: Array[StringName] = []
var mass: float = 1.0
var charge: float = 0.0
var stability: float = 1.0
var class_tags: Array[StringName] = []

var resource_pools: Dictionary = {}
var status_manager: StatusManager = null

var _abilities: Dictionary = {}
var _profiles: Dictionary = {}
var _profile_sources: Dictionary = {}
var _profile_uid := 0
var _ability_overrides: Dictionary = {}

func _enter_tree() -> void:
    _ensure_status_manager()

func _ready() -> void:
    _recalculate_stats()
    _initialize_resources()
    _update_instability_factor()
    if particle_class:
        var initial: ParticleClassDefinition = particle_class
        particle_class = null
        set_particle_class(initial)

func set_particle_class(value: ParticleClassDefinition) -> void:
    _ensure_status_manager()
    if value == _particle_class:
        return
    _clear_abilities()
    _particle_class = value
    if _particle_class:
        mass = _particle_class.mass
        charge = _particle_class.charge
        stability = _particle_class.stability
        class_tags.clear()
        for tag in _particle_class.class_tags:
            if typeof(tag) == TYPE_STRING_NAME:
                class_tags.append(tag)
            else:
                class_tags.append(StringName(tag))
        _initialize_resources()
        var loadout: Dictionary = _particle_class.create_loadout()
        for slot in loadout:
            _set_ability(StringName(slot), loadout[slot])
    else:
        mass = 1.0
        charge = 0.0
        stability = 1.0
        class_tags.clear()
        _initialize_resources()
    _update_instability_factor()
    _update_status_immunities()
    emit_signal("class_changed", _particle_class)

func get_status_manager() -> StatusManager:
    return status_manager

func set_resource(resource_name: StringName, current: float, maximum: float) -> void:
    var normalized_name := StringName(resource_name)
    maximum = max(maximum, 0.0)
    var pool := {
        "current": clamp(current, 0.0, maximum if maximum > 0.0 else current),
        "max": maximum,
    }
    if maximum <= 0.0:
        pool["current"] = max(current, 0.0)
    resource_pools[normalized_name] = pool
    emit_signal("resource_changed", normalized_name, pool["current"], pool["max"])
    if normalized_name == &"stability":
        _update_instability_factor()

func modify_resource(resource_name: StringName, delta: float) -> void:
    var normalized_name := StringName(resource_name)
    var pool: Dictionary = resource_pools.get(normalized_name, {})
    var max_amount := float(pool.get("max", 0.0))
    var current := float(pool.get("current", 0.0)) + delta
    if max_amount > 0.0:
        current = clamp(current, 0.0, max_amount)
    else:
        current = max(current, 0.0)
        max_amount = max(max_amount, current)
    pool["current"] = current
    pool["max"] = max_amount
    resource_pools[normalized_name] = pool
    emit_signal("resource_changed", normalized_name, current, max_amount)
    if normalized_name == &"stability":
        _update_instability_factor()

func get_resource_amount(resource_name: StringName) -> float:
    var normalized_name := StringName(resource_name)
    var pool: Dictionary = resource_pools.get(normalized_name, {})
    return float(pool.get("current", 0.0))

func get_resource_capacity(resource_name: StringName) -> float:
    var normalized_name := StringName(resource_name)
    var pool: Dictionary = resource_pools.get(normalized_name, {})
    return float(pool.get("max", 0.0))

func has_resources(costs: Dictionary) -> bool:
    for cost_name in costs.keys():
        if get_resource_amount(StringName(cost_name)) + 0.0001 < float(costs[cost_name]):
            return false
    return true

func get_missing_resources(costs: Dictionary) -> Dictionary:
    var missing := {}
    for cost_name in costs.keys():
        var required := float(costs[cost_name])
        var available := get_resource_amount(StringName(cost_name))
        if available + 0.0001 < required:
            missing[cost_name] = required - available
    return missing

func apply_resource_costs(costs: Dictionary) -> bool:
    if not has_resources(costs):
        return false
    for cost_name in costs.keys():
        modify_resource(StringName(cost_name), -float(costs[cost_name]))
    return true

func restore_resource(resource_name: StringName, amount: float) -> void:
    var normalized_name := StringName(resource_name)
    if amount <= 0.0:
        return
    modify_resource(normalized_name, amount)

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
        if ability.has_method("set_slot"):
            ability.set_slot(slot)
        else:
            ability.slot = slot
        ability.on_equip(self)

func _clear_abilities() -> void:
    clear_all_ability_overrides()
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

func override_ability(slot: StringName, ability_id: StringName, duration: float, source: Variant) -> bool:
    slot = StringName(slot)
    var ability_instance: Variant = ABILITY_CATALOG.create(StringName(ability_id))
    var ability: ParticleAbility = ability_instance if ability_instance is ParticleAbility else null
    if ability == null:
        push_warning("PlayerAvatar: Unable to override ability %s" % ability_id)
        return false
    _clear_override_for_slot(slot)
    var original_instance: Variant = _abilities.get(slot)
    var original: ParticleAbility = original_instance if original_instance is ParticleAbility else null
    _ability_overrides[slot] = {
        "original": original,
        "source": source,
    }
    _set_ability(slot, ability)
    if duration > 0.0:
        var timer := Timer.new()
        timer.one_shot = true
        timer.wait_time = duration
        add_child(timer)
        timer.timeout.connect(_on_ability_override_timeout.bind(slot, source, timer))
        timer.start()
        _ability_overrides[slot]["timer"] = timer
    return true

func remove_ability_override(source: Variant) -> void:
    var slots: Array[StringName] = []
    for slot in _ability_overrides.keys():
        var data: Dictionary = _ability_overrides[slot]
        if source == null or data.get("source") == source:
            slots.append(slot)
    for slot in slots:
        _clear_override_for_slot(StringName(slot))

func clear_all_ability_overrides() -> void:
    remove_ability_override(null)

func _clear_override_for_slot(slot: StringName) -> void:
    if not _ability_overrides.has(slot):
        return
    var data: Dictionary = _ability_overrides[slot]
    var timer_variant: Variant = data.get("timer")
    var timer: Timer = timer_variant if timer_variant is Timer else null
    if is_instance_valid(timer):
        timer.stop()
        timer.queue_free()
    var original_variant: Variant = data.get("original")
    var original: ParticleAbility = original_variant if original_variant is ParticleAbility else null
    _ability_overrides.erase(slot)
    _set_ability(slot, original)

func _on_ability_override_timeout(slot: StringName, source: Variant, timer: Timer) -> void:
    if not _ability_overrides.has(slot):
        timer.queue_free()
        return
    var data: Dictionary = _ability_overrides[slot]
    if data.get("source") != source:
        timer.queue_free()
        return
    _clear_override_for_slot(slot)

func apply_stat_profile(source: Variant, profile: Dictionary) -> void:
    var key := _profile_key(source)
    _profiles[key] = _normalize_profile(profile)
    _profile_sources[key] = source
    _recalculate_stats()

func apply_temporary_profile(source: Variant, profile: Dictionary, duration: float) -> void:
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

func remove_stat_profile(source: Variant) -> void:
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

func _profile_key(source: Variant, suffix: String = "") -> StringName:
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

func has_class_tag(tag: StringName) -> bool:
    tag = StringName(tag)
    return tag in class_tags

func has_any_class_tag(tags: Array) -> bool:
    for tag in tags:
        if has_class_tag(StringName(tag)):
            return true
    return false

func get_class_tags() -> Array[StringName]:
    return class_tags.duplicate()

func _ensure_status_manager() -> void:
    if status_manager:
        return
    var manager_instance = STATUS_MANAGER_SCRIPT.new()
    status_manager = manager_instance if manager_instance is StatusManager else null
    if status_manager == null:
        push_error("PlayerAvatar: Failed to instantiate StatusManager")
        return
    status_manager.name = "StatusManager"
    status_manager.host = self
    add_child(status_manager)
    _update_status_immunities()

func _initialize_resources() -> void:
    resource_pools.clear()
    set_resource(&"energy", 100.0, 100.0)
    var stability_capacity: float = max(stability, 0.0) * 100.0
    if stability_capacity <= 0.0:
        stability_capacity = 1.0
    set_resource(&"stability", stability_capacity, stability_capacity)

func _update_instability_factor() -> void:
    if status_manager == null:
        return
    var baseline: float = clamp(1.0 - stability, 0.0, 1.0)
    var stability_pool: Dictionary = resource_pools.get(&"stability", {})
    var max_amount := float(stability_pool.get("max", 0.0))
    if max_amount > 0.0:
        var ratio: float = float(stability_pool.get("current", max_amount)) / max_amount
        baseline = max(baseline, 1.0 - ratio)
    status_manager.set_instability_factor(baseline)

func _update_status_immunities() -> void:
    if status_manager == null:
        return
    status_manager.clear_immunities()
    if particle_class and LEPTON_IDS.has(particle_class.id):
        status_manager.set_immunity(&"strong_force", true)
