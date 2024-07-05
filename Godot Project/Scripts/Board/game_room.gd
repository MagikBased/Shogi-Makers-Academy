extends Node2D
class_name GameRoom

@onready var board_scene = preload("res://Scenes/board.tscn")
var board_padding: int = 54

func _ready():
	var board = board_scene.instantiate()
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
