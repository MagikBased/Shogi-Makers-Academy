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
		if piece.fen_char_piece_to_add_on_capture and not sente_in_hand.has(piece.fen_char_piece_to_add_on_capture) and piece.can_add_to_hand:
			var capture_fen := piece.fen_char_piece_to_add_on_capture
			sente_in_hand[capture_fen] = 0
			gote_in_hand[capture_fen.to_lower()] = 0
	if game_variant.in_hand_pieces:
		initialize_hand_containers()
		populate_hand_containers()
		update_hand()

func initialize_hand_containers() -> void:
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
		in_hand_piece.piece_owner = Player.Sente
		in_hand_piece.square_size = game_manager.square_size
		#in_hand_piece.scale *= game_manager.board.scale
		in_hand_piece.game_manager = game_manager
		sente_container.add_child(in_hand_piece)
	for fen_char in gote_in_hand.keys():
		var piece_base = get_piece_base_from_fen_char(fen_char.to_lower())
		var in_hand_piece = in_hand_piece_scene.instantiate() as InHandPiece
		in_hand_piece.piece_resource = piece_base
		in_hand_piece.player = Player.Gote
		in_hand_piece.piece_owner = Player.Gote
		in_hand_piece.square_size = game_manager.square_size
		#in_hand_piece.scale *= game_manager.board.scale
		in_hand_piece.game_manager = game_manager
		gote_container.add_child(in_hand_piece)
	sente_container.arrange_children()
	gote_container.arrange_children()

func add_piece_to_hand(player: Player, piece: PieceBase) -> void:
	if player == Player.Sente:
		sente_in_hand[piece.fen_char_piece_to_add_on_capture] += 1
	elif player == Player.Gote:
		gote_in_hand[piece.fen_char_piece_to_add_on_capture.to_lower()] += 1
	update_hand()

func remove_piece_from_hand(player: Player, piece: PieceBase) -> void: #Consider making this a bool
	if player == Player.Sente and sente_in_hand[piece.fen_char] > 0:
		sente_in_hand[piece.fen_char] -= 1
	elif player == Player.Gote and gote_in_hand[piece.fen_char.to_lower()] > 0:
		gote_in_hand[piece.fen_char.to_lower()] -= 1
	update_hand()

func reset_in_hand_pieces() -> void:
	for key in sente_in_hand.keys():
		sente_in_hand[key] = 0
	for key in gote_in_hand.keys():
		gote_in_hand[key] = 0

func update_hand() -> void:
	for piece_node in sente_container.get_children():
		if piece_node is InHandPiece:
			var fen_char = piece_node.piece_resource.fen_char_piece_to_add_on_capture
			var piece_count = sente_in_hand[fen_char] if sente_in_hand.has(fen_char) else 0
			piece_node.update_alpha(piece_count)
	for piece_node in gote_container.get_children():
		if piece_node is InHandPiece:
			var fen_char = piece_node.piece_resource.fen_char_piece_to_add_on_capture.to_lower()
			var piece_count = gote_in_hand[fen_char] if gote_in_hand.has(fen_char) else 0
			piece_node.update_alpha(piece_count)

func get_piece_base_from_fen_char(fen_char: String) -> PieceBase:
	for piece in game_variant.pieces:
		if piece.fen_char == fen_char or piece.fen_char.to_lower() == fen_char:
			return piece
	return null

func get_piece_count_in_hand(player: Player, piece_fen_char: String) -> int:
	if player == Player.Sente:
		return sente_in_hand.get(piece_fen_char, 0)
	else:
		return gote_in_hand.get(piece_fen_char, 0)

func update_piece_scales(new_square_size: float) -> void:
	for container in [sente_container, gote_container]:
		if container:
			for child in container.get_children():
				if child is InHandPiece:
					var texture_width = child.texture.get_width()
					if texture_width > 0:
						var scale_factor = new_square_size / texture_width
						child.scale = Vector2.ONE * scale_factor
