extends Node2D
class_name GameRoom

var game_manager: GameManager
@export var game_variant: GameVariant
@onready var board_scene = preload("res://Scenes/GameBoardScenes/board.tscn")
@onready var game_manager_scene = preload("res://Scenes/GameBoardScenes/game_manager.tscn")
@onready var in_hand_scene = preload("res://Scenes/GameBoardScenes/in_hand_manager.tscn")
@onready var fen_manager_scene = preload("res://Scenes/GameBoardScenes/fen_manager.tscn")
@onready var debug_manager_scene = preload("res://Scenes/GameBoardScenes/debug_manager.tscn")
var board_padding: int = 54

func _ready() -> void:
	game_manager = game_manager_scene.instantiate() as GameManager
	var board = board_scene.instantiate() as Board
	var fen_manager = fen_manager_scene.instantiate() as FenManager
	var debug = debug_manager_scene.instantiate() as DebugManager

	game_manager.set_variant(game_variant)
	board.set_variant(game_variant)
	game_manager.board = board
	resize_board(board)
	game_manager.square_size = board.get_rect().size.x / float(game_variant.board_data.board_size.x)

	fen_manager.game_variant = game_variant
	fen_manager.game_manager = game_manager
	game_manager.fen_manager = fen_manager

	debug.game_manager = game_manager
	game_manager.debug_manager = debug

	if game_variant.in_hand_pieces:
		var in_hand_manager = in_hand_scene.instantiate() as InHandManager
		in_hand_manager.game_variant = game_variant
		in_hand_manager.game_manager = game_manager
		game_manager.in_hand_manager = in_hand_manager
		game_manager.add_child(in_hand_manager)

	game_manager.add_child(board)
	game_manager.add_child(fen_manager)
	add_child(game_manager)
	add_child(debug)

	if game_manager.in_hand_manager:
		game_manager.in_hand_manager.update_piece_scales(game_manager.square_size * board.scale.x)


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
