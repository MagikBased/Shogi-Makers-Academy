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
var move_buttons: Array[Button] = []
var selected_color: Color = Color(0.4, 0.6, 1.0)

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
	_update_button_selection()

func _add_move_button(number: int, notation: String) -> void:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var number_label = Label.new()
	number_label.text = str(number)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_child(number_label)
	var move_button = Button.new()
	move_button.text = notation
	move_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	move_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	move_button.pressed.connect(_on_move_button_pressed.bind(number))
	move_button.focus_mode = Control.FOCUS_NONE
	row.add_child(margin)
	row.add_child(move_button)
	move_list.add_child(row)
	move_buttons.append(move_button)
	_scroll_to_bottom_if_needed()

func _on_move_button_pressed(index: int) -> void:
	_set_board_to_index(index)

func _scroll_to_bottom_if_needed() -> void:
	var bar: VScrollBar = $Panel/ScrollContainer.get_v_scroll_bar()
	var at_bottom: bool = bar.value >= bar.max_value - bar.page
	await get_tree().process_frame
	if at_bottom:
		bar.value = bar.max_value

func _update_button_selection() -> void:
	for i in range(move_buttons.size()):
		var button: Button = move_buttons[i]
		button.modulate = selected_color if i + 1 == current_index else Color.WHITE

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
	var capture = (
		prev_board.has(to_square)
		and prev_board[to_square] != ""
		and not _is_player_piece(prev_board[to_square], player)
	)
	var piece_type = _strip_plus(from_char).to_upper()
	var show_from := _is_ambiguous_move(prev_board, from_char, from_square, to_square, player)
	var notation = piece_type
	if show_from:
		notation += _coord_to_string(from_square)
	notation += ("x" if capture else "-") + _coord_to_string(to_square)
	var could_promote = false
	var idx = game_manager.fen_manager.get_piece_type_from_symbol(piece_type)
	if idx != -1:
		var piece_base: PieceBase = game_manager.game_variant.pieces[idx]
		could_promote = _can_promote_move(piece_base, from_square, to_square, player)
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

func _is_inside_board(pos: Vector2i) -> bool:
	return pos.x > 0 and pos.x <= game_manager.board.board_size.x and pos.y > 0 and pos.y <= game_manager.board.board_size.y
func _can_promote_move(piece_base: PieceBase, from_pos: Vector2i, to_pos: Vector2i, player: GameManager.Player) -> bool:
	if not piece_base.can_promote or piece_base.is_promoted:
		return false
	for square in piece_base.promotion_squares:
		if square.player != PromotionSquare.Player.Both and square.player != player:
			continue
		var in_start = square.position == from_pos
		var in_end = square.position == to_pos
		match square.promotion_move_rule:
			PromotionSquare.PromotionMove.Both:
				if in_start or in_end:
					return true
			PromotionSquare.PromotionMove.MovesInto:
				if not in_start and in_end:
					return true
			PromotionSquare.PromotionMove.MovesOutOf:
				if in_start and not in_end:
					return true
	return false

func _piece_can_move_to(board: Dictionary, piece_char: String, from_pos: Vector2i, to_pos: Vector2i, player: GameManager.Player) -> bool:
	var idx = game_manager.fen_manager.get_piece_type_from_symbol(_strip_plus(piece_char).to_upper())
	if idx == -1:
		return false
	var piece_base: PieceBase = game_manager.game_variant.pieces[idx]
	for move in piece_base.moves:
		if move is StampMove:
			for dir in move.move_directions:
				var direction = dir
				if player == GameManager.Player.Gote:
					direction = Vector2i(-dir.x, -dir.y)
				var target = from_pos + direction
				if target != to_pos:
					continue
				if not _is_inside_board(target):
					continue
				match move.restriction:
					MovementBase.MoveRestriction.CAPTURE_ONLY:
						return board.has(target) and not _is_player_piece(board.get(target, ""), player)
					MovementBase.MoveRestriction.MOVE_ONLY:
						return not board.has(target)
					MovementBase.MoveRestriction.NONE:
						return not _is_player_piece(board.get(target, ""), player)
		elif move is SwingMove:
			var direction = move.move_direction
			if player == GameManager.Player.Gote:
				direction = Vector2i(-direction.x, -direction.y)
			var target = from_pos + direction
			var distance = 0
			while _is_inside_board(target) and (move.max_distance == -1 or distance < move.max_distance):
				if target == to_pos:
					var occupied = board.has(target)
					if move.restriction == MovementBase.MoveRestriction.CAPTURE_ONLY:
						return occupied and not _is_player_piece(board.get(target, ""), player)
					if move.restriction == MovementBase.MoveRestriction.MOVE_ONLY and occupied:
						return false
					return not (occupied and _is_player_piece(board.get(target, ""), player))
				if board.has(target):
					break
				target += direction
				distance += 1
	return false

func _is_ambiguous_move(board: Dictionary, piece_char: String, from_pos: Vector2i, to_pos: Vector2i, player: GameManager.Player) -> bool:
	var piece_type = _strip_plus(piece_char).to_upper()
	var temp_board: Dictionary = board.duplicate()
	temp_board.erase(from_pos)
	for pos in temp_board.keys():
		if pos == from_pos:
			continue
		var character = temp_board[pos]
		if _strip_plus(character).to_upper() != piece_type:
			continue
		if not _is_player_piece(character, player):
			continue
		if _piece_can_move_to(temp_board, character, pos, to_pos, player):
			return true
	return false
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
	$Panel.set_deferred("size", size)
