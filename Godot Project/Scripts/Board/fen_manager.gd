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

func create_board_from_fen(fen: String) -> void:
	game_manager.clear_board()
	var parts = fen.split(" ")
	var board_state = parts[0]
	var player_turn = parts[1]
	var in_hand_pieces = parts[2]
	var turn_count = parts[3]
	
	var regex = RegEx.new()
	regex.compile("([1-9]|\\+[A-Za-z]|[A-Za-z])")
	var matches = regex.search_all(board_state)
	
	var x = 0
	var y = 0
	for amatch in matches:
		var match_string = amatch.get_string()
		var is_promoted = match_string.begins_with("+")
		
		if is_promoted:
			match_string = match_string.substr(1)
		
		if match_string.is_valid_int():
			x += int(match_string)
		else:
			var piece_type_index = get_piece_type_from_symbol(match_string.to_upper())
			if piece_type_index == -1:
				continue

			var piece_base = game_variant.pieces[piece_type_index]
			var piece_owner
			if match_string == match_string.to_upper():
				piece_owner = game_manager.Player.Sente
			else:
				piece_owner = game_manager.Player.Gote
			game_manager.create_piece(piece_base, Vector2(game_manager.board.board_size.x - x, y + 1), piece_owner)
			x += 1
		
		if x > game_manager.board.board_size.x - 1:
			x = 0
			y += 1
	
	regex.compile("(\\d*[A-Za-z])")
	var in_hand_matches = regex.search_all(in_hand_pieces)
	
	for amatch in in_hand_matches:
		var piece_string = amatch.get_string()
		var count = 1
		var piece_char
		
		if piece_string.length() > 1:
			count = int(piece_string.substr(0, piece_string.length() - 1))
			piece_char = piece_string[-1]
		else:
			piece_char = piece_string

		var piece_type_index = get_piece_type_from_symbol(piece_char.to_upper())
		if piece_type_index == -1:
			continue
		
		var piece_base = game_variant.pieces[piece_type_index]
		for i in range(count):
			if piece_char == piece_char.to_upper():
				game_manager.in_hand_manager.add_piece_to_hand(game_manager.in_hand_manager.Player.Sente, piece_base)
			else:
				game_manager.in_hand_manager.add_piece_to_hand(game_manager.in_hand_manager.Player.Gote, piece_base)
	
	if player_turn == "b":
		game_manager.player_turn = game_manager.Player.Sente
	elif player_turn == "w":
		game_manager.player_turn = game_manager.Player.Gote
	game_manager.turn_count = int(turn_count)

func initialize_piece_to_index() -> void:
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
	create_board_from_fen(fen_line_edit.text)
