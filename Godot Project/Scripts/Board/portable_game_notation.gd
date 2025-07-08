extends Control
class_name PortableGameNotation

@onready var move_list: VBoxContainer = $Panel/ScrollContainer/MovesVBox
@onready var first_button: Button = $Panel/ButtonsHBox/FirstButton
@onready var back_button: Button = $Panel/ButtonsHBox/BackButton
@onready var forward_button: Button = $Panel/ButtonsHBox/ForwardButton
@onready var last_button: Button = $Panel/ButtonsHBox/LastButton

var game_manager: GameManager
var history: Array[String] = []
var move_notations: Array[String] = []
var current_index: int = 0

func _ready() -> void:
	first_button.pressed.connect(_on_first_pressed)
	back_button.pressed.connect(_on_back_pressed)
	forward_button.pressed.connect(_on_forward_pressed)
	last_button.pressed.connect(_on_last_pressed)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_setup_layout()
	_align_to_viewport()
	get_viewport().size_changed.connect(_align_to_viewport)

func add_sfen(sfen: String) -> void:
	history.append(sfen)
	if history.size() > 1:
		var notation = _compute_move_notation(history[history.size() - 2], sfen)
		move_notations.append(notation)
		_add_move_button(history.size() - 1, notation)
	_set_board_to_index(history.size() - 1)

func _on_first_pressed() -> void:
	_set_board_to_index(0)

func _on_back_pressed() -> void:
	_set_board_to_index(max(current_index - 1, 0))

func _on_forward_pressed() -> void:
	_set_board_to_index(min(current_index + 1, history.size() - 1))

func _on_last_pressed() -> void:
	_set_board_to_index(history.size() - 1)

func _set_board_to_index(index: int) -> void:
	game_manager.cancel_promotion()
	if index < 0 or index >= history.size():
		return
	current_index = index
	var sfen = history[index]
	game_manager.fen_manager.create_board_from_fen(sfen)
	game_manager.start_phase()
	game_manager.allow_input = index == history.size() - 1

func _add_move_button(number: int, notation: String) -> void:
	var row = HBoxContainer.new()
	var move_button = Button.new()
	move_button.text = str(number)
	move_button.pressed.connect(_on_move_button_pressed.bind(number))
	var label = Label.new()
	label.text = notation
	row.add_child(move_button)
	row.add_child(label)
	move_list.add_child(row)

func _on_move_button_pressed(index: int) -> void:
	_set_board_to_index(index)

func _compute_move_notation(prev_sfen: String, new_sfen: String) -> String:
	var prev_parts = prev_sfen.split(" ")
	var new_parts = new_sfen.split(" ")
	var prev_board = _parse_board(prev_parts[0])
	var new_board = _parse_board(new_parts[0])
	var prev_hand = _parse_hand(prev_parts[2] if prev_parts.size() > 2 else "-")
	var new_hand = _parse_hand(new_parts[2] if new_parts.size() > 2 else "-")
	var player = GameManager.Player.Sente if prev_parts[1] == "b" else GameManager.Player.Gote
	var drop_piece = ""
	for piece in prev_hand.keys():
		var prev_count = prev_hand[piece]
		var new_count = new_hand.get(piece, 0)
		if player == GameManager.Player.Sente and piece == piece.to_upper() and new_count < prev_count:
			drop_piece = piece.to_upper()
			break
		elif player == GameManager.Player.Gote and piece == piece.to_lower() and new_count < prev_count:
			drop_piece = piece.to_upper()
			break
	if drop_piece != "":
		for pos in new_board.keys():
			if not prev_board.has(pos) and _is_player_piece(new_board[pos], player):
				return drop_piece + "*" + _coord_to_string(pos)
	var from_square = null
	var to_square = null
	var from_char = ""
	var to_char = ""
	for pos in prev_board.keys():
		var prev_char = prev_board[pos]
		var curr_char = new_board.get(pos, "")
		if _is_player_piece(prev_char, player) and prev_char != curr_char:
			from_square = pos
			from_char = prev_char
			break
	for pos in new_board.keys():
		var prev_char = prev_board.get(pos, "")
		var curr_char = new_board[pos]
		if _is_player_piece(curr_char, player) and curr_char != prev_char:
			to_square = pos
			to_char = curr_char
			break
	if from_square == null or to_square == null:
		return ""
	var capture = prev_board.has(to_square) and prev_board[to_square] != "" and not _is_player_piece(prev_board[to_square], player)
	var piece_type = _strip_plus(from_char).to_upper()
	var notation = piece_type + ("x" if capture else "-") + _coord_to_string(to_square)
	var could_promote = false
	var idx = game_manager.fen_manager.get_piece_type_from_symbol(piece_type)
	if idx != -1:
		var piece_base: PieceBase = game_manager.game_variant.pieces[idx]
		could_promote = piece_base.can_promote and not piece_base.is_promoted
	var promoted = not from_char.begins_with("+") and to_char.begins_with("+")
	if could_promote:
		notation += "+" if promoted else "="
	return notation

func _parse_board(board_str: String) -> Dictionary:
	var result: Dictionary = {}
	var ranks = board_str.split("/")
	for y in range(ranks.size()):
		var row = ranks[y]
		var x = 0
		var i = 0
		while i < row.length():
			var c = row[i]
			if c.is_valid_int():
				x += int(c)
			else:
				var piece_char = c
				if c == "+" and i + 1 < row.length():
					i += 1
					piece_char += row[i]
				var file = game_manager.board.board_size.x - x
				var rank = y + 1
				result[Vector2i(file, rank)] = piece_char
				x += 1
			i += 1
	return result

func _parse_hand(hand_str: String) -> Dictionary:
	var counts: Dictionary = {}
	if hand_str == "-" or hand_str == "":
		return counts
	var number = ""
	for c in hand_str:
		if c.is_valid_int():
			number += c
		else:
			var count = int(number) if number != "" else 1
			counts[c] = counts.get(c, 0) + count
			number = ""
	return counts

func _coord_to_string(pos: Vector2i) -> String:
	return str(pos.x) + str(pos.y)

func _is_player_piece(character: String, player: GameManager.Player) -> bool:
	return (player == GameManager.Player.Sente and character == character.to_upper()) or (player == GameManager.Player.Gote and character == character.to_lower())

func _strip_plus(character: String) -> String:
	return character.substr(1) if character.begins_with("+") else character

func _setup_layout() -> void:
	$Panel.anchor_left = 0.0
	$Panel.anchor_top = 0.0
	$Panel.anchor_right = 1.0
	$Panel.anchor_bottom = 1.0
	$Panel.offset_left = 0.0
	$Panel.offset_top = 0.0
	$Panel.offset_right = 0.0
	$Panel.offset_bottom = 0.0
	$Panel/ScrollContainer.anchor_left = 0.0
	$Panel/ScrollContainer.anchor_top = 0.0
	$Panel/ScrollContainer.anchor_right = 1.0
	$Panel/ScrollContainer.anchor_bottom = 1.0
	$Panel/ScrollContainer.offset_left = 0.0
	$Panel/ScrollContainer.offset_top = 0.0
	$Panel/ScrollContainer.offset_right = 0.0
	$Panel/ScrollContainer.offset_bottom = -40.0
	$Panel/ButtonsHBox.anchor_left = 0.0
	$Panel/ButtonsHBox.anchor_right = 1.0
	$Panel/ButtonsHBox.anchor_top = 1.0
	$Panel/ButtonsHBox.anchor_bottom = 1.0
	$Panel/ButtonsHBox.offset_left = 0.0
	$Panel/ButtonsHBox.offset_right = 0.0
	$Panel/ButtonsHBox.offset_top = -40.0
	$Panel/ButtonsHBox.offset_bottom = 0.0

func _align_to_viewport() -> void:
	var viewport_size = get_viewport_rect().size
	var width = 200.0
	var height = viewport_size.y * 2.0 / 3.0
	position = Vector2(viewport_size.x - width, (viewport_size.y - height) / 2.0)
	size = Vector2(width, height)
	$Panel.size = size
