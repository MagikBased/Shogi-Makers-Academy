extends Node2D
class_name  GameManager

enum Player{
	Sente,
	Gote
}

var game_variant: GameVariant
var board: Board
var square_size: float
var pieces_on_board: Array[PieceInfo] = []
var turn_count: int = 1
var player_turn: Player = Player.Sente
var in_hand_manager: InHandManager
var fen_manager: FenManager

func _ready():
	initialize_values()
	fen_manager.create_board_from_fen(game_variant.starting_fen)

func initialize_values() -> void:
	square_size = (board.texture.get_width()) / board.board_size.x

func create_piece(piece_base: PieceBase, starting_position: Vector2, piece_owner: Player) -> void:
	var piece_scene = load("res://Scenes/GameBoardScenes/game_piece.tscn")
	var piece = piece_scene.instantiate() as BaseGamePiece
	piece.piece_resource = piece_base
	piece.current_position = starting_position
	piece.game_manager = self
	piece.piece_owner = piece_owner
	board.add_child(piece)
	
	var piece_info: PieceInfo = PieceInfo.new()
	piece_info.position = starting_position
	piece_info.owner = piece.piece_owner
	piece_info.piece_type = piece_base.fen_char
	piece_info.instance_id = piece.get_instance_id()
	pieces_on_board.append(piece_info)

func clear_board() -> void:
	for piece_info in pieces_on_board:
		var piece_instance = instance_from_id(piece_info.instance_id)
		if piece_instance:
			piece_instance.queue_free()
	pieces_on_board.clear()
	if game_variant.in_hand_pieces:
		in_hand_manager.reset_in_hand_pieces()

func set_variant(game_varient: GameVariant) -> void:
	game_variant = game_varient

func find_square_center(file: int,rank: int) -> Vector2:
	var center_x = (game_variant.board_data.board_size.x + 1 - file) * square_size - square_size / 2
	var center_y = rank * square_size - square_size / 2
	return Vector2(center_x, center_y)
