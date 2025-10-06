extends RunModifierCallback

const STABILITY_DRAIN := 6.0

func on_stage_advance(_system, player, _data: Dictionary, _stage_index: int, _context: Dictionary = {}) -> void:
    if player == null:
        return
    player.modify_resource(&"stability", -STABILITY_DRAIN)
