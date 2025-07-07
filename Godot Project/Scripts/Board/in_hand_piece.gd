extends BaseGamePiece
class_name InHandPiece

@export var player: InHandManager.Player
@onready var count_label = $PieceCount
var square_size: float

func _ready() -> void:
	if piece_resource and piece_resource.icon.size() > 0:
		piece_sprite.texture = piece_resource.icon[0]
	scale *= square_size / piece_sprite.texture.get_size().x
	rect_size = Vector2(piece_sprite.texture.get_width(), piece_sprite.texture.get_height())

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var local_mouse_position = to_local(event.position)
		var is_over_sprite = piece_sprite.get_rect().has_point(local_mouse_position)
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and is_over_sprite:
			var piece_count = game_manager.in_hand_manager.get_piece_count_in_hand(
				player,
				piece_resource.fen_char_piece_to_add_on_capture if player == Player.Sente else piece_resource.fen_char_piece_to_add_on_capture.to_lower()
			)
			if piece_owner == game_manager.player_turn and piece_count > 0 and not game_manager.is_promoting and game_manager.allow_input:
				was_selected_on_press = selected
				if selected:
					destroy_all_highlights()
					set_selected(false)
					game_manager.selected_piece = null
				else:
					if game_manager.selected_piece != null:
						game_manager.selected_piece.destroy_all_highlights()
						game_manager.selected_piece.set_selected(false)
					set_selected(true)
					game_manager.selected_piece = self
					get_valid_moves()
					show_valid_move_highlights()
				begin_drag(event)

		elif not event.is_pressed() and dragging:
			end_drag()
			var drop_square := Vector2i(-1, -1)
			for child in get_children():
				if child is SquareHighlight:
					var local_mouse = child.to_local(event.position)
					if child.get_rect().has_point(local_mouse):
						drop_square = child.current_position
						break
			if drop_square in valid_moves:
				_on_drop_piece(drop_square)
			else:
				if was_selected_on_press:
					set_selected(false)
					game_manager.selected_piece = null
				else:
					set_selected(true)
					game_manager.selected_piece = self
	elif event is InputEventMouseMotion:
		update_drag(event)

func begin_drag(event: InputEventMouseButton) -> void:
	dragging = true
	drag_sprite = Sprite2D.new()
	drag_sprite.texture = piece_sprite.texture
	drag_sprite.scale = scale / game_manager.board.scale
	drag_sprite.rotation = global_rotation
	drag_sprite.z_index = z_index + 100
	game_manager.board.add_child(drag_sprite)
	drag_sprite.position = game_manager.board.to_local(event.position)
	piece_sprite.modulate.a = 0.25
	queue_redraw()
	game_manager.record_move()

func get_valid_moves() -> void:
	valid_moves.clear()
	var king_position = game_manager.find_kings(piece_owner)[0]
	var checking_pieces = game_manager.determine_checks(king_position, piece_owner)
	var blocking_squares := []
	if checking_pieces.size() == 1:
		var checking_piece = checking_pieces[0]
		blocking_squares = get_blocking_squares(king_position, checking_piece)
	var board_size = game_manager.board.board_size
	for x in range(1, board_size.x + 1):
		for y in range(1, board_size.y + 1):
			var move_position = Vector2i(x, y)
			if not is_inside_board(move_position):
				continue
			if is_space_taken(move_position):
				continue
			if is_illegal_drop_square(move_position) or violates_drop_restrictions(move_position):
				continue
			if not piece_resource.can_deliver_checkmate and would_cause_checkmate(move_position):
				continue
			if checking_pieces.size() == 1 and move_position not in blocking_squares:
				continue
			elif checking_pieces.size() > 1:
				continue
			valid_moves.append(move_position)

func show_valid_move_highlights() -> void:
	for moves in valid_moves:
		var highlight = square_highlight.instantiate() as SquareHighlight
		highlight.is_dropping = true
		highlight.connect("drop_piece", Callable(self, "_on_drop_piece"))
		add_child(highlight)
		highlight.set_board_position(moves)

func _on_drop_piece(move_position: Vector2i) -> void:
	game_manager.in_hand_manager.remove_piece_from_hand(player, piece_resource)
	var gm_player = GameManager.Player.Sente if player == InHandManager.Player.Sente else GameManager.Player.Gote
	game_manager.create_piece(piece_resource, move_position, gm_player)
	destroy_all_highlights()
	if game_manager.handle_action(piece_resource.fen_char, TurnAction.ActionType.DropPiece):
		game_manager.selected_piece = null
		set_selected(false)
		queue_redraw()
		game_manager.record_move()

func update_alpha(count: int) -> void:
	self.modulate.a = 1.0 if count > 0 else 0.3
	count_label.text = str(count)
	count_label.position = piece_sprite.texture.get_size() / 4.0
	count_label.z_index = self.z_index + 1

func destroy_all_highlights() -> void:
	for child in get_children():
		if child.is_in_group("highlight"):
			child.queue_free()

func get_blocking_squares(king_pos: Vector2i, attacker: PieceInfo) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var direction = (king_pos - attacker.position).sign()
	var pos = attacker.position + direction
	while pos != king_pos:
		result.append(pos)
		pos += direction
	return result

func is_illegal_drop_square(move_position: Vector2i) -> bool:
	if piece_resource.illegal_drop_squares.size() == 0:
		return false
	for illegal_square in piece_resource.illegal_drop_squares:
		if illegal_square.move_position == move_position and (illegal_square.player == IllegalDropSquare.Player.Both or illegal_square.player == piece_owner):
			return true
	return false

func violates_drop_restrictions(move_position: Vector2i) -> bool:
	for restriction in piece_resource.drop_restrictions:
		var rank_count = 0
		var file_count = 0
		for piece_info in game_manager.pieces_on_board:
			var is_allied = piece_info.owner == piece_owner
			var is_opponent = piece_info.owner != piece_owner
			var valid_rank_check = restriction.check_rank and piece_info.position.y == move_position.y
			var valid_file_check = restriction.check_file and piece_info.position.x == move_position.x
			var matches_type = piece_info.piece_type == restriction.piece_type
			var matches_ownership = false
			match restriction.ownership_type:
				DropRestriction.OwnershipType.Allied:
					matches_ownership = is_allied
				DropRestriction.OwnershipType.Opponent:
					matches_ownership = is_opponent
				DropRestriction.OwnershipType.Both:
					matches_ownership = true
			if matches_type and matches_ownership:
				if valid_rank_check:
					rank_count += 1
				if valid_file_check:
					file_count += 1
		if (restriction.check_rank and rank_count >= restriction.count) or (restriction.check_file and file_count >= restriction.count):
			return true
	return false

func would_cause_checkmate(drop_position: Vector2i) -> bool:
	var king_position = game_manager.find_kings(GameManager.Player.Gote if player == GameManager.Player.Sente else GameManager.Player.Sente)[0]
	var king_instance = game_manager.get_piece_instance_at(king_position)
	if not king_instance:
		return false
	var king_moves: Array[Vector2i] = king_instance.generate_moves()
	var danger_squares = game_manager.get_squares_attacked_by_player(game_manager.player_turn)
	var safe_moves = []
	for pos in king_moves:
		if pos not in danger_squares and not is_space_taken(pos):
			safe_moves.append(pos)
	var relative_vector = king_position - drop_position
	for move in piece_resource.moves:
		if move is StampMove:
			for dir in move.move_directions:
				var adjusted = dir
				if player == GameManager.Player.Gote:
					adjusted = -dir
				if adjusted == relative_vector:
					return safe_moves.is_empty()
		elif move is SwingMove:
			var dir = move.move_direction
			if player == GameManager.Player.Gote:
				dir = -dir
			if relative_vector.sign() == dir.sign():
				var delta = king_position - drop_position
				var dist = max(abs(delta.x), abs(delta.y))
				if move.max_distance == -1 or dist <= move.max_distance:
					return safe_moves.is_empty()
	return false

func is_inside_board(move: Vector2i) -> bool:
	return move.x > 0 and move.x <= game_manager.board.board_size.x and move.y > 0 and move.y <= game_manager.board.board_size.y

func is_space_taken(move: Vector2i) -> bool:
	for piece_info in game_manager.pieces_on_board:
		if piece_info.position == move:
			return true
	return false
