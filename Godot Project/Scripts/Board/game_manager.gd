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

var selected_piece: BaseGamePiece = null
var is_promoting:bool = false

func _ready() -> void:
	initialize_values()
	fen_manager.create_board_from_fen(game_variant.starting_fen)

func initialize_values() -> void:
	square_size = (board.texture.get_width()) / float(board.board_size.x)

func create_piece(piece_base: PieceBase, starting_position: Vector2, piece_owner: Player) -> void:
	var piece_scene = load("res://Scenes/GameBoardScenes/game_piece.tscn")
	var piece = piece_scene.instantiate() as BaseGamePiece
	piece.piece_resource = piece_base
	piece.current_position = starting_position
	piece.game_manager = self
	piece.piece_owner = piece_owner
	piece.is_promoted = piece_base.is_promoted
	board.add_child(piece)
	
	var piece_info: PieceInfo = PieceInfo.new()
	piece_info.position = starting_position
	piece_info.owner = piece.piece_owner
	piece_info.piece_type = piece_base.fen_char
	piece_info.instance_id = piece.get_instance_id()
	piece_info.piece_base = piece.piece_resource
	pieces_on_board.append(piece_info)

func get_legal_moves(player: Player) -> Array:
	var legal_moves: Array = []
	for piece_info in pieces_on_board:
		if piece_info.owner == player:
			var piece_instance = instance_from_id(piece_info.instance_id)
			var piece_moves = piece_instance.generate_moves()
			for move in piece_moves:
				if is_legal_move(piece_instance, move):
					legal_moves.append(move)
	return legal_moves

func is_legal_move(piece: BaseGamePiece, move: Vector2) -> bool:
	#needs logic
	return not move_puts_king_in_check(piece, move)

func move_puts_king_in_check(piece: BaseGamePiece, _move: Vector2) -> bool:
	#needs logic
	return is_king_in_check(piece.piece_owner)

func is_king_in_check(player: Player) -> bool:
	var king_positions = find_kings(player)
	var opponent = Player.Gote if player == Player.Sente else Player.Sente
	var opponent_legal_moves = get_legal_moves(opponent)
	for king_position in king_positions:
		if king_position in opponent_legal_moves:
			return true
	return false

func find_kings(player: Player) -> Array[Vector2i]:
	var king_positions: Array[Vector2i] = []
	for piece_info in pieces_on_board:
		if piece_info.owner == player and piece_info.piece_base.is_royal:
			king_positions.append(piece_info.position)
	return king_positions

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

func _input(event):
	if event is InputEventKey and event.pressed:
		print(is_king_in_check(Player.Gote))

