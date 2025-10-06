extends RefCounted
class_name RunModifierCallback

## Base callback used by run modifiers to hook into lifecycle events.
func on_applied(_system, _player, _data: Dictionary, _context: Dictionary = {}) -> void:
    pass

func on_removed(_system, _player, _data: Dictionary, _context: Dictionary = {}) -> void:
    pass

func on_stage_advance(_system, _player, _data: Dictionary, _stage_index: int, _context: Dictionary = {}) -> void:
    pass
