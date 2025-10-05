extends Node

const DEFAULT_ACTIONS := {
    &"move_left": {
        "keys": [Key.KEY_A, Key.KEY_LEFT],
        "joypad_axes": [{"axis": JOY_AXIS_LEFT_X, "value": -1.0}],
    },
    &"move_right": {
        "keys": [Key.KEY_D, Key.KEY_RIGHT],
        "joypad_axes": [{"axis": JOY_AXIS_LEFT_X, "value": 1.0}],
    },
    &"move_up": {
        "keys": [Key.KEY_W, Key.KEY_UP],
        "joypad_axes": [{"axis": JOY_AXIS_LEFT_Y, "value": -1.0}],
    },
    &"move_down": {
        "keys": [Key.KEY_S, Key.KEY_DOWN],
        "joypad_axes": [{"axis": JOY_AXIS_LEFT_Y, "value": 1.0}],
    },
    &"dash": {
        "keys": [Key.KEY_SPACE],
        "joypad_buttons": [JOY_BUTTON_A],
    },
    &"interact": {
        "keys": [Key.KEY_E, Key.KEY_ENTER],
        "joypad_buttons": [JOY_BUTTON_B],
    },
}

func _ready() -> void:
    apply_default_bindings()

func apply_default_bindings() -> void:
    for action_name in DEFAULT_ACTIONS.keys():
        _register_action(action_name, DEFAULT_ACTIONS[action_name])

func reset_action(action_name: StringName) -> void:
    if InputMap.has_action(action_name):
        InputMap.action_erase_events(action_name)
    else:
        InputMap.add_action(action_name)

func register_custom_action(action_name: StringName, events: Array) -> void:
    reset_action(action_name)
    for input_event in events:
        InputMap.action_add_event(action_name, input_event)

func _register_action(action_name: StringName, definition: Dictionary) -> void:
    reset_action(action_name)
    for keycode in definition.get("keys", []):
        var key_event := InputEventKey.new()
        key_event.physical_keycode = int(keycode)
        InputMap.action_add_event(action_name, key_event)
    for button in definition.get("joypad_buttons", []):
        var button_event := InputEventJoypadButton.new()
        button_event.button_index = int(button)
        InputMap.action_add_event(action_name, button_event)
    for axis_data in definition.get("joypad_axes", []):
        var motion_event := InputEventJoypadMotion.new()
        motion_event.axis = int(axis_data.get("axis", JOY_AXIS_LEFT_X))
        motion_event.axis_value = float(axis_data.get("value", 0.0))
        InputMap.action_add_event(action_name, motion_event)

func get_action_events(action_name: StringName) -> Array:
    if not InputMap.has_action(action_name):
        return []
    return InputMap.action_get_events(action_name)

func ensure_action(action_name: StringName) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)
