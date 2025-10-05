extends Node

var _rng := RandomNumberGenerator.new()
var _seed: int = 0

func _ready() -> void:
	if _seed == 0:
		randomize()

func randomize() -> void:
	set_seed(generate_seed_from_time())

func set_seed(seed_value: int) -> void:

    _seed = int(abs(seed_value))
    if _seed == 0:
        _seed = 1
    _rng.seed = _seed

	_seed = int(abs(seed_value))
	if _seed == 0:
		_seed = 1
	_rng.seed = _seed


func get_seed() -> int:
	return _seed

func randf() -> float:
	return _rng.randf()

func randf_range(min_value: float, max_value: float) -> float:
	return _rng.randf_range(min_value, max_value)

func randi() -> int:
	return _rng.randi()

func randi_range(min_value: int, max_value: int) -> int:
	return _rng.randi_range(min_value, max_value)

func shuffle(array: Array) -> void:
	_rng.shuffle(array)

func generate_seed_from_time() -> int:
	var time_seed := int(Time.get_unix_time_from_system() * 1000.0)
	time_seed &= 0x7fffffff
	if time_seed == 0:
		time_seed = 1
	return time_seed

func get_state() -> Dictionary:
    return {
        "seed": _seed,
        "state": _rng.state,
    }

func set_state(state_data: Dictionary) -> void:
    if state_data.is_empty():
        return
    _seed = int(abs(state_data.get("seed", _seed)))
    if _seed == 0:
        _seed = 1
    _rng.seed = _seed
    var rng_state = state_data.get("state")
    if rng_state != null:
        _rng.state = rng_state
	return {
		"seed": _seed,
		"state": _rng.state,
	}

func set_state(state_data: Dictionary) -> void:
	if state_data.is_empty():
		return
	_seed = int(abs(state_data.get("seed", _seed)))
	if _seed == 0:
		_seed = 1
	_rng.seed = _seed
	var rng_state = state_data.get("state")
	if rng_state != null:
		_rng.state = rng_state

