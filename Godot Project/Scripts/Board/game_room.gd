extends Node2D
class_name GameRoom

var game_manager: GameManager
@export var game_variant: GameVariant
@onready var board_scene = preload("res://Scenes/GameBoardScenes/board.tscn")
@onready var game_manager_scene = preload("res://Scenes/GameBoardScenes/game_manager.tscn")

var board_padding: int = 54

func _ready():
	game_manager = game_manager_scene.instantiate() as GameManager
	game_manager.set_variant(game_variant)
	add_child(game_manager)
	var board = board_scene.instantiate() as Board
	board.set_variant(game_variant)
	add_child(board)
	resize_board(board)

func resize_board(board) -> void:
	var rect = get_viewport_rect().size
	var board_size = min(rect.x - board_padding * 2, rect.y - board_padding * 2)
	var board_scale_x: float = board_size / board.texture.get_width()
	var board_scale_y: float = board_size / board.texture.get_height()
	board.scale = Vector2(board_scale_x, board_scale_y)
	var offset_x: float = (board.texture.get_width() * board_scale_x) / 2
	var offset_y: float = (board.texture.get_height() * board_scale_y) / 2
	board.position.x = rect.x / 2 - offset_x
	board.position.y = rect.y / 2 - offset_y
