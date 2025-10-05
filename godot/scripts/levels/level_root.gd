extends Node2D
class_name LevelRoot

@onready var _player_spawn: Marker2D = %PlayerSpawn
@onready var _player: Node2D = %Player
@onready var _camera: Camera2D = %Camera2D
@onready var _game_controller: GameController = %GameController

func _ready() -> void:
    _position_player_at_spawn()
    _ensure_camera_synced()
    _ensure_controller_player_reference()

func _position_player_at_spawn() -> void:
    if not is_instance_valid(_player) or not is_instance_valid(_player_spawn):
        return
    _player.global_position = _player_spawn.global_position

func _ensure_camera_synced() -> void:
    if not is_instance_valid(_camera) or not is_instance_valid(_player):
        return
    _camera.position = Vector2.ZERO
    if _camera.get_parent() != _player:
        _camera.global_position = _player.global_position

func _ensure_controller_player_reference() -> void:
    if not is_instance_valid(_game_controller) or not is_instance_valid(_player):
        return
    if _game_controller.player_path.is_empty():
        _game_controller.player_path = _game_controller.get_path_to(_player)
