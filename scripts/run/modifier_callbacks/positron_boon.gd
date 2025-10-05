extends RunModifierCallback

const ENERGY_REPLENISH := 12.0

func on_stage_advance(_system, player, _data: Dictionary, _stage_index: int, _context: Dictionary = {}) -> void:
    if player == null:
        return
    player.restore_resource(&"energy", ENERGY_REPLENISH)
