extends Node2D
class_name InHandManager

enum Player{
	Sente,
	Gote
}
var game_variant: GameVariant
var game_manager: GameManager
var sente_in_hand: Dictionary = {}
var gote_in_hand: Dictionary = {}
var sente_container: InHandContainer
var gote_container: InHandContainer
@onready var in_hand_container_scene = preload("res://Scenes/GameBoardScenes/in_hand_piece_container.tscn")
@onready var in_hand_piece_scene = preload("res://Scenes/GameBoardScenes/in_hand_piece.tscn")

func _ready() -> void:
	for piece in game_variant.pieces:
		if piece.fen_char_piece_to_add_on_capture and not sente_in_hand.has(piece.fen_char_piece_to_add_on_capture):
			sente_in_hand[piece.fen_char] = 0
			gote_in_hand[piece.fen_char.to_lower()] = 0
	if game_variant.in_hand_pieces:
		initalize_hand_containers()
		populate_hand_containers()
		#for fen_char in sente_in_hand.keys():
			#var piece_base = get_piece_base_from_fen_char(fen_char)
			#var in_hand_piece = in_hand_piece_scene.instantiate() as InHandPiece
			#in_hand_piece.piece_resource = piece_base
			#in_hand_piece.player = Player.Sente
			#sente_container.add_child(in_hand_piece)
		#for fen_char in gote_in_hand.keys():
			#var piece_base = get_piece_base_from_fen_char(fen_char)
			#var in_hand_piece = in_hand_piece_scene.instantiate() as InHandPiece
			#in_hand_piece.piece_resource = piece_base
			#in_hand_piece.player = Player.Gote
			#gote_container.add_child(in_hand_piece)

func initalize_hand_containers() -> void:
	sente_container = in_hand_container_scene.instantiate() as InHandContainer
	gote_container = in_hand_container_scene.instantiate() as InHandContainer
	sente_container.player = Player.Sente
	gote_container.player = Player.Gote
	add_child(sente_container)
	add_child(gote_container)
	sente_container.position = Vector2(100,200)
	gote_container.position = Vector2(200,200)
	#sente_container.position = Vector2(game_manager.board.position.x + game_manager.board.texture.get_width(), game_manager.board.position.y)
	#gote_container.position = Vector2(game_manager.board.position.x - game_manager.board.square_size, game_manager.board.position.y)

func populate_hand_containers() -> void:
	for fen_char in sente_in_hand.keys():
		var piece_base = get_piece_base_from_fen_char(fen_char)
		var in_hand_piece = in_hand_piece_scene.instantiate() as InHandPiece
		in_hand_piece.piece_resource = piece_base
		in_hand_piece.player = Player.Sente
		sente_container.add_child(in_hand_piece)
	for fen_char in gote_in_hand.keys():
		var piece_base = get_piece_base_from_fen_char(fen_char)
		var in_hand_piece = in_hand_piece_scene.instantiate() as InHandPiece
		in_hand_piece.piece_resource = piece_base
		in_hand_piece.player = Player.Gote
		gote_container.add_child(in_hand_piece)

func add_piece_to_hand(player: Player, piece: PieceBase) -> void:
	if player == Player.Sente:
		sente_in_hand[piece.fen_char_piece_to_add_on_capture] += 1
	elif player == Player.Gote:
		gote_in_hand[piece.fen_char_piece_to_add_on_capture] += 1

func remove_piece_from_hand(player: Player, piece: PieceBase) -> void: #Consider making this a bool
	if player == Player.Sente and sente_in_hand[piece.fen_char] > 0:
		sente_in_hand[piece.fen_char] -= 1
	elif player == Player.Gote and gote_in_hand[piece.fen_char] > 0:
		gote_in_hand[piece.fen_char] -= 1

func reset_in_hand_pieces() -> void:
	for key in sente_in_hand.keys():
		sente_in_hand[key] = 0
	for key in gote_in_hand.keys():
		gote_in_hand[key] = 0

func get_piece_base_from_fen_char(fen_char: String) -> PieceBase:
	for piece in game_variant.pieces:
		if piece.fen_char == fen_char or piece.fen_char.to_lower() == fen_char:
			return piece
	return null
