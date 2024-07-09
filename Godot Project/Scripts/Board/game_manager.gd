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

func _ready():
	initialize_values()
	create_piece(game_variant.pieces[0], Vector2(5,9), Player.Sente)
	create_piece(game_variant.pieces[1], Vector2(2,8), Player.Sente)
	create_piece(game_variant.pieces[3], Vector2(8,8), Player.Sente)
	create_piece(game_variant.pieces[5], Vector2(4,9), Player.Sente)
	create_piece(game_variant.pieces[5], Vector2(6,9), Player.Sente)
	create_piece(game_variant.pieces[6], Vector2(7,9), Player.Sente)
	create_piece(game_variant.pieces[6], Vector2(3,9), Player.Sente)
	create_piece(game_variant.pieces[8], Vector2(2,9), Player.Sente)
	create_piece(game_variant.pieces[8], Vector2(8,9), Player.Sente)
	create_piece(game_variant.pieces[10], Vector2(1,9), Player.Sente)
	create_piece(game_variant.pieces[10], Vector2(9,9), Player.Sente)
	create_piece(game_variant.pieces[12], Vector2(1,7), Player.Sente)
	create_piece(game_variant.pieces[12], Vector2(2,7), Player.Sente)
	create_piece(game_variant.pieces[12], Vector2(3,7), Player.Sente)
	create_piece(game_variant.pieces[12], Vector2(4,7), Player.Sente)
	create_piece(game_variant.pieces[12], Vector2(5,7), Player.Sente)
	create_piece(game_variant.pieces[12], Vector2(6,7), Player.Sente)
	create_piece(game_variant.pieces[12], Vector2(7,7), Player.Sente)
	create_piece(game_variant.pieces[12], Vector2(8,7), Player.Sente)
	create_piece(game_variant.pieces[12], Vector2(9,7), Player.Sente)
	
	create_piece(game_variant.pieces[12], Vector2(1,3), Player.Gote)
	create_piece(game_variant.pieces[12], Vector2(2,3), Player.Gote)
	create_piece(game_variant.pieces[12], Vector2(3,3), Player.Gote)
	create_piece(game_variant.pieces[12], Vector2(4,3), Player.Gote)
	create_piece(game_variant.pieces[12], Vector2(5,3), Player.Gote)
	create_piece(game_variant.pieces[12], Vector2(6,3), Player.Gote)
	create_piece(game_variant.pieces[12], Vector2(7,3), Player.Gote)
	create_piece(game_variant.pieces[12], Vector2(8,3), Player.Gote)
	create_piece(game_variant.pieces[12], Vector2(9,3), Player.Gote)
	create_piece(game_variant.pieces[3], Vector2(2,2), Player.Gote)
	create_piece(game_variant.pieces[1], Vector2(8,2), Player.Gote)
	create_piece(game_variant.pieces[10], Vector2(1,1), Player.Gote)
	create_piece(game_variant.pieces[10], Vector2(9,1), Player.Gote)
	create_piece(game_variant.pieces[8], Vector2(2,1), Player.Gote)
	create_piece(game_variant.pieces[8], Vector2(8,1), Player.Gote)
	create_piece(game_variant.pieces[6], Vector2(3,1), Player.Gote)
	create_piece(game_variant.pieces[6], Vector2(7,1), Player.Gote)
	create_piece(game_variant.pieces[5], Vector2(6,1), Player.Gote)
	create_piece(game_variant.pieces[5], Vector2(4,1), Player.Gote)
	create_piece(game_variant.pieces[0], Vector2(5,1), Player.Gote)
	

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


func set_variant(game_varient: GameVariant) -> void:
	game_variant = game_varient

func find_square_center(file: int,rank: int) -> Vector2:
	var center_x = (game_variant.board_data.board_size.x + 1 - file) * square_size - square_size / 2
	var center_y = rank * square_size - square_size / 2
	return Vector2(center_x, center_y)
