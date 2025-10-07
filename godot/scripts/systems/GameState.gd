extends Node

signal run_started(seed: int, metadata: Dictionary)
signal run_ended(results: Dictionary)
signal level_changed(level_path: String)

var is_run_active: bool = false
var current_level: StringName = &""
var run_seed: int = 0
var run_metadata: Dictionary = {}

func _ready() -> void:
    if not is_run_active:
        run_seed = RunRNG.generate_seed_from_time()
        RunRNG.set_seed(run_seed)
        run_metadata = {}

func start_new_run(seed: int = RunRNG.generate_seed_from_time(), metadata: Dictionary = {}) -> void:
    run_seed = seed
    run_metadata = metadata.duplicate(true)
    RunRNG.set_seed(run_seed)
    is_run_active = true
    current_level = &""
    emit_signal("run_started", run_seed, run_metadata.duplicate(true))

func end_run(results: Dictionary = {}) -> void:
    if not is_run_active:
        return
    is_run_active = false
    emit_signal("run_ended", results.duplicate(true))

func set_level(level_path: String) -> void:
    var normalized := StringName(level_path if level_path != null else "")
    if current_level == normalized:
        return
    current_level = normalized
    emit_signal("level_changed", String(current_level))

func get_run_context() -> Dictionary:
    return {
        "seed": run_seed,
        "metadata": run_metadata.duplicate(true),
        "level": String(current_level),
        "active": is_run_active,
    }

func reset() -> void:
    is_run_active = false
    current_level = &""
    run_seed = 0
    run_metadata.clear()
