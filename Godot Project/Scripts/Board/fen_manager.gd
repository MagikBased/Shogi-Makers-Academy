extends Node2D
class_name FenManager

@onready var get_fen_button = $GetFENButton
@onready var set_fen_button = $SetFENButton
@onready var fen_line_edit = $FENLineEdit

var game_manager: GameManager
var game_variant: GameVariant
var piece_to_index: Dictionary = {}

func _ready():
	initialize_piece_to_index()

func get_fen_notation() -> String:
	var sfen = ""
	var empty_count = 0
	for rank in range(0, game_manager.board.board_size.y):
		for file in range(game_manager.board.board_size.x - 1, -1, -1):
			var current_position = Vector2(file + 1, rank + 1)
			var piece_found = false
			for piece_info in game_manager.pieces_on_board:
				if piece_info.position == current_position:
					piece_found = true
					if empty_count > 0:
						sfen += str(empty_count)
						empty_count = 0

					var piece_owner = piece_info.owner
					var piece_type_index = get_piece_type_from_symbol(piece_info.piece_type)
					if piece_type_index == -1:
						continue

					var piece_base = game_variant.pieces[piece_type_index]
					var piece_char = piece_base.fen_char
					if piece_owner == game_manager.Player.Gote:
						piece_char = piece_char.to_lower()

					if instance_from_id(piece_info.instance_id).is_promoted:
						piece_char = "+" + piece_char
					sfen += piece_char
					break
			if not piece_found:
				empty_count += 1
		if empty_count > 0:
			sfen += str(empty_count)
			empty_count = 0
		if rank < game_manager.board.board_size.y - 1:
			sfen += "/"
	sfen += " "

	if game_manager.player_turn == game_manager.Player.Sente:
		sfen += "b"
	else:
		sfen += "w"
	sfen += " "
	if game_manager.game_variant.in_hand_pieces:
		var hand_notation = ""
		var sente_hand = game_manager.in_hand_manager.sente_in_hand
		var gote_hand = game_manager.in_hand_manager.gote_in_hand
		for key in sente_hand.keys():
			var count = sente_hand[key]
			if count > 0:
				hand_notation += str(count) + key if count > 1 else key
		for key in gote_hand.keys():
			var count = gote_hand[key]
			if count > 0:
				hand_notation += str(count) + key if count > 1 else key
		sfen += hand_notation
	sfen += "- " + str(game_manager.turn_count)
	return sfen

func initialize_piece_to_index():
	if game_variant and game_variant.pieces:
		for i in range(game_variant.pieces.size()):
			var piece = game_variant.pieces[i]
			piece_to_index[piece.fen_char] = i
			piece_to_index[piece.fen_char.to_lower()] = i

func get_piece_type_from_symbol(symbol: String) -> int:
	if piece_to_index.has(symbol):
		return piece_to_index[symbol]
	else:
		print("Unknown piece symbol: ", symbol)
		return -1

func _on_get_fen_button_pressed():
	fen_line_edit.text = get_fen_notation()

func _on_set_fen_button_pressed():
	pass # Replace with function body.
