extends Node2D
class_name GameManager

enum Player{
	Sente,
	Gote,
	Neutral,
	Both,
}

var game_variant: GameVariant
var board: Board
var square_size: float
var pieces_on_board: Array[PieceInfo] = []
var player_turn: Player = Player.Sente
var turn_count: int = 1
var current_phase: TurnPhase = null
var current_action_count: int = 0
var in_hand_manager: InHandManager
var fen_manager: FenManager
var debug_manager: DebugManager
var notation_manager: PostGameNotation
var allow_input: bool = true

var selected_piece: BaseGamePiece = null
var is_promoting:bool = false

var attack_cache = {
	"Sente": {
		"swinging": {},
		"stamp": {},
	},
	"Gote": {
		"swinging": {},
		"stamp": {},
	}
}

var active_piece_set: PieceSet

func _ready() -> void:
	active_piece_set = game_variant.piece_sets[0]
	initialize_values()
	if game_variant.debug_fen.strip_edges() != "":
		fen_manager.create_board_from_fen(game_variant.debug_fen)
	else:
		fen_manager.create_board_from_fen(game_variant.starting_fen)
	record_move()
	initialize_attack_cache()
	#print(attack_cache)
	start_phase()

func initialize_values() -> void:
	square_size = (board.texture.get_width()) / float(board.board_size.x)
	current_phase = game_variant.turn_phases[0]

func start_phase() -> void:
	debug_manager.clear_highlights()
	current_action_count = 0
	clear_constrained_moves()
	for piece_info in pieces_on_board:
		var piece_instance = instance_from_id(piece_info.instance_id) as BaseGamePiece
		if piece_instance:
			piece_instance.valid_moves = piece_instance.generate_moves()
			if piece_info.owner == player_turn:
				filter_illegal_royal_moves(piece_instance)
	if game_variant.win_conditions.has(GameVariant.WinConditions.CHECKMATE) or game_variant.win_conditions.has(GameVariant.WinConditions.NUMBER_OF_CHECKS):
		var king_position = find_kings(player_turn)[0]
		determine_pins(king_position, player_turn)
		
		var checking_pieces = determine_checks(king_position, player_turn)
		#print("Checking pieces: ", checking_pieces.size())
		if checking_pieces.size() > 0:
			constrain_moves_due_to_check(king_position, checking_pieces)
	
	#var opponent = Player.Gote if player_turn == Player.Sente else Player.Sente
	#var danger_squares = get_squares_attacked_by_player(opponent)
	#debug_manager.add_highlights(danger_squares, Color.RED)

func handle_action(piece_type: String, action_type: TurnAction.ActionType) -> bool:
	if current_phase.player != player_turn:
		print("It's not your turn!")
		return false
	for action in current_phase.actions:
		if action.action_type == action_type:
			#print("Action allowed: ", action_type, " for piece: ", piece_type)
			current_action_count += 1
			if game_variant.win_conditions.has(GameVariant.WinConditions.CHECKMATE) or game_variant.win_conditions.has(GameVariant.WinConditions.NUMBER_OF_CHECKS):
				var king_position = find_kings(player_turn)[0]
				determine_pins(king_position, player_turn)
			if current_action_count >= current_phase.max_actions_per_turn:
				end_phase()
			return true
	print("Action not allowed: ", action_type, " for piece: ", piece_type)
	return false

#func can_perform_action(action: TurnAction, piece_type: String, piece_owner: Player) -> bool:
	#if current_action_count >= action.max_actions:
		#return false
	#if action.specific_pieces.size() > 0 and piece_type in action.specific_pieces:
		#return true
	#match action.piece_ownership:
		#TurnAction.PiecesForAction.Allied:
			#return piece_owner == player_turn
		#TurnAction.PiecesForAction.Enemy:
			#return piece_owner != player_turn
		#TurnAction.PiecesForAction.Neutral:
			#return piece_owner == Player.Neutral
		#TurnAction.PiecesForAction.Any:
			#return true
	#return false

func end_phase() -> void:
	advance_turn()

func advance_turn() -> void:
	#print("Ending phase for player: ", player_turn)
	turn_count += 1
	switch_turn()
	if game_variant.win_conditions.has(GameVariant.WinConditions.CHECKMATE) or game_variant.win_conditions.has(GameVariant.WinConditions.NUMBER_OF_CHECKS):
		var king_position = find_kings(player_turn)[0]
		determine_pins(king_position, player_turn)

func switch_turn() -> void:
	player_turn = Player.Sente if player_turn == Player.Gote else Player.Gote
	var phase_index = (turn_count - 1) % game_variant.turn_phases.size()
	current_phase = game_variant.turn_phases[phase_index]
	start_phase()
	if game_variant.win_conditions.has(GameVariant.WinConditions.CHECKMATE) or game_variant.win_conditions.has(GameVariant.WinConditions.NUMBER_OF_CHECKS):
		var king_position = find_kings(player_turn)[0]
		determine_pins(king_position, player_turn)

func initialize_attack_cache() -> void:
	for piece in game_variant.pieces:
		var swing_vectors_sente = get_piece_attack_vectors(piece, Player.Sente, "swinging")
		var stamp_vectors_sente = get_piece_attack_vectors(piece, Player.Sente, "stamp")
		var swing_vectors_gote = get_piece_attack_vectors(piece, Player.Gote, "swinging")
		var stamp_vectors_gote = get_piece_attack_vectors(piece, Player.Gote, "stamp")
		if swing_vectors_sente.size() > 0:
			attack_cache["Sente"]["swinging"][piece.fen_char] = swing_vectors_sente
		if stamp_vectors_sente.size() > 0:
			attack_cache["Sente"]["stamp"][piece.fen_char] = stamp_vectors_sente
		if swing_vectors_gote.size() > 0:
			attack_cache["Gote"]["swinging"][piece.fen_char] = swing_vectors_gote
		if stamp_vectors_gote.size() > 0:
			attack_cache["Gote"]["stamp"][piece.fen_char] = stamp_vectors_gote
	#print(attack_cache)

func get_piece_attack_vectors(piece_base: PieceBase, player: Player, move_type: String) -> Array:
	var attack_vectors = []
	for move in piece_base.moves:
		if move.restriction == MovementBase.MoveRestriction.MOVE_ONLY:
			continue
		match move_type:
			"swinging":
				if move is SwingMove:
					var direction = move.move_direction
					if player == Player.Gote:
						direction = Vector2i(-direction.x, -direction.y)
					attack_vectors.append(direction)
			"stamp":
				if move is StampMove:
					for direction in move.move_directions:
						var adjusted_direction = direction
						if player == Player.Gote:
							adjusted_direction = Vector2i(-direction.x, -direction.y)
						attack_vectors.append(adjusted_direction)
	return attack_vectors

func piece_threatens_king(piece_info: PieceInfo, king_position: Vector2i) -> bool:
	var piece_base = piece_info.piece_base
	var swing_attack_vectors = []
	var stamp_attack_vectors = []
	if piece_info.owner == Player.Sente:
		swing_attack_vectors = attack_cache["Sente"]["swinging"].get(piece_base.fen_char, [])
		stamp_attack_vectors = attack_cache["Sente"]["stamp"].get(piece_base.fen_char, [])
	else:
		swing_attack_vectors = attack_cache["Gote"]["swinging"].get(piece_base.fen_char, [])
		stamp_attack_vectors = attack_cache["Gote"]["stamp"].get(piece_base.fen_char, [])
	for direction in stamp_attack_vectors:
		var attack_position = piece_info.position + direction
		if attack_position == king_position:
			return true
	for direction in swing_attack_vectors:
		var target_position = piece_info.position + direction
		while is_inside_board(target_position):
			if target_position == king_position:
				return true
			if is_space_taken(target_position):
				break
			target_position += direction
	return false

func determine_pins(king_position: Vector2i, player: Player) -> Array:
	var opponent = Player.Gote if player == Player.Sente else Player.Sente
	var potential_pins = []
	var opponent_str = "Sente" if opponent == Player.Gote else "Gote"
	for piece_info in pieces_on_board:
		if piece_info.owner == opponent:
			var swing_attack_vectors = attack_cache[opponent_str]["swinging"].get(piece_info.piece_base.fen_char, [])
			for direction in swing_attack_vectors:
				var path: Array[Vector2i] = []
				var target_position = piece_info.position + direction
				var piece_in_path = null
				while is_inside_board(target_position):
					path.append(target_position)
					if is_space_taken(target_position):
						var occupying_piece_info = get_piece_info_at_position(target_position)
						if occupying_piece_info.piece_base.is_royal:
							break
						if occupying_piece_info.owner == player:
							if piece_in_path != null: 
								piece_in_path = null
								break
							else:
								piece_in_path = occupying_piece_info
						elif occupying_piece_info.owner == opponent:
							break
					target_position += direction
				if piece_in_path != null and target_position == king_position:
					path.append(piece_info.position)
					constrain_moves(piece_in_path, path)
					potential_pins.append(piece_in_path)
	return potential_pins

func determine_checks(king_position: Vector2i, player: Player) -> Array[PieceInfo]:
	var opponent = Player.Gote if player == Player.Sente else Player.Sente
	var checking_pieces: Array[PieceInfo] = []
	for piece_info in pieces_on_board:
		if piece_info.owner == opponent:
			if piece_threatens_king(piece_info, king_position):
				#print("Checking piece: ", piece_info.piece_type, " at ", piece_info.position)
				checking_pieces.append(piece_info)

	return checking_pieces

func constrain_moves(piece_info: PieceInfo, constrained_moves: Array[Vector2i]) -> void:
	var piece_instance = instance_from_id(piece_info.instance_id) as BaseGamePiece
	if piece_instance:
		var legal_constrained_moves: Array[Vector2i] = []
		for move in piece_instance.valid_moves:
			if move in constrained_moves:
				legal_constrained_moves.append(move)
		if legal_constrained_moves.size() == 0:
			piece_instance.is_fully_constrained = true
		else:
			piece_instance.is_fully_constrained = false
		for move in legal_constrained_moves:
			if not piece_instance.constrained_moves.has(move):
				piece_instance.constrained_moves.append(move)

func constrain_moves_due_to_check(king_position: Vector2i, checking_pieces: Array[PieceInfo]) -> void:
	#print(">>> Constraining moves due to check")
	#print("King position: ", king_position)
	#print("Number of checking pieces: ", checking_pieces.size())

	for piece_info in pieces_on_board:
		if piece_info.owner != player_turn:
			continue

		var piece_instance = instance_from_id(piece_info.instance_id) as BaseGamePiece
		if not piece_instance:
			continue

		piece_instance.constrained_moves.clear()
		#print("\nEvaluating piece: ", piece_info.piece_type, " at ", piece_info.position)

		if piece_info.piece_base.is_royal:
			#print("- This is the king. Checking for safe escape squares.")
			var opponent = Player.Gote if player_turn == Player.Sente else Player.Sente
			var danger_squares = get_squares_attacked_by_player(opponent, piece_info.instance_id)
			for move in piece_instance.valid_moves:
				if move in danger_squares:
					pass
					#print("  ! Move ", move, " is attacked by opponent — not safe for king")
				else:
					piece_instance.constrained_moves.append(move)
					#print("  ✓ Safe move for king: ", move)
			piece_instance.is_fully_constrained = piece_instance.constrained_moves.size() == 0
		else:
			#print("- This is not the king. Checking for blocking/capturing moves.")
			var move_sets_per_check: Array = []

			for checking_piece in checking_pieces:
				var valid_responses: Array[Vector2i] = []
				#print("  Checking against threat from ", checking_piece.piece_type, " at ", checking_piece.position)

				for move in piece_instance.valid_moves:
					if move == checking_piece.position:
						valid_responses.append(move)
						#print("    ✓ Move captures attacker at ", move)
					elif is_blocking_move_valid(king_position, move, checking_piece):
						valid_responses.append(move)
						#print("    ✓ Move blocks check at ", move)

				move_sets_per_check.append(valid_responses)

			var intersection: Array[Vector2i] = []
			if move_sets_per_check.size() > 0:
				intersection = move_sets_per_check[0].duplicate()
				for i in range(1, move_sets_per_check.size()):
					intersection = intersection.filter(
						func(m): return m in move_sets_per_check[i]
					)

			if intersection.size() > 0:
				for move in intersection:
					piece_instance.constrained_moves.append(move)
					piece_instance.is_fully_constrained = false
				#print("  ✓ Final legal constrained moves: ", intersection)
			else:
				piece_instance.is_fully_constrained = true
				#print("  ✗ No legal responses to ALL threats.")

func filter_illegal_royal_moves(piece: BaseGamePiece) -> void:
	if not piece.piece_resource.is_royal:
		return
	var opponent = Player.Gote if piece.piece_owner == Player.Sente else Player.Sente
	var danger_squares = get_squares_attacked_by_player(opponent, piece.get_instance_id())
	var filtered: Array[Vector2i] = []
	for move in piece.valid_moves:
		if move not in danger_squares:
			filtered.append(move)
	piece.constrained_moves = filtered
	piece.is_fully_constrained = filtered.size() == 0

func is_blocking_move_valid(king_position: Vector2i, move: Vector2i, attacking_piece_info: PieceInfo) -> bool:
	var blocking_positions = []
	var opponent_str = ""
	if attacking_piece_info.owner == Player.Sente:
		opponent_str = "Sente"
	else:
		opponent_str = "Gote"
	var swing_attack_vectors = attack_cache[opponent_str]["swinging"].get(attacking_piece_info.piece_base.fen_char, [])
	for direction in swing_attack_vectors:
		var target_position = attacking_piece_info.position + direction
		while is_inside_board(target_position):
			if target_position == king_position:
				target_position = attacking_piece_info.position + direction
				while target_position != king_position:
					blocking_positions.append(target_position)
					target_position += direction
				break
			elif is_space_taken(target_position):
				break
			target_position += direction
	return move in blocking_positions

func get_squares_attacked_by_player(player: Player, exclude_instance_id := -1) -> Array[Vector2i]:
	var attacked_squares: Array[Vector2i] = []
	var player_str = "Sente" if player == Player.Sente else "Gote"
	for piece_info in pieces_on_board:
		if piece_info.owner != player:
			continue
		if piece_info.instance_id == exclude_instance_id:
			continue
		var piece_instance = instance_from_id(piece_info.instance_id) as BaseGamePiece
		if not piece_instance:
			continue
		var key = piece_info.piece_base.fen_char
		if piece_instance.is_promoted and not key.begins_with("+"):
			key = "+" + key
		var swing_vectors = attack_cache[player_str]["swinging"].get(key, [])
		var stamp_vectors = attack_cache[player_str]["stamp"].get(key, [])
		for direction in swing_vectors:
			var pos = piece_info.position + direction
			while is_inside_board(pos):
				attacked_squares.append(pos)
				if is_space_taken(pos, exclude_instance_id):
					break
				pos += direction
		for direction in stamp_vectors:
			var pos = piece_info.position + direction
			if is_inside_board(pos):
				attacked_squares.append(pos)
	return attacked_squares

func find_attacking_piece(king_position: Vector2i, player: Player) -> PieceInfo:
	var opponent = Player.Gote if player == Player.Sente else Player.Sente
	for piece_info in pieces_on_board:
		if piece_info.owner == opponent:
			if piece_threatens_king(piece_info, king_position):
				#print(piece_info.position)
				return piece_info
	return null

func clear_constrained_moves() -> void:
	for piece_info in pieces_on_board:
		var piece_instance = instance_from_id(piece_info.instance_id) as BaseGamePiece
		if piece_instance:
			piece_instance.is_fully_constrained = false
			piece_instance.constrained_moves.clear()

func get_piece_info_at_position(board_position: Vector2i) -> PieceInfo:
	for piece_info in pieces_on_board:
		if piece_info.position == board_position:
			return piece_info
	return null

func get_piece_instance_at(pos: Vector2i) -> BaseGamePiece:
	for info in pieces_on_board:
		if info.position == pos:
			return instance_from_id(info.instance_id)
	return null

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
				#if is_legal_move(piece_instance, move):
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

func record_move() -> void:
	if notation_manager and fen_manager:
	notation_manager.add_sfen(fen_manager.get_fen_notation())

func set_variant(variant: GameVariant) -> void:
	game_variant = variant

#func get_current_phase(turn_count: int) -> TurnPhase:
	#return turn_phases[(turn_count - 1) % turn_phases.size()]

func find_square_center(file: int,rank: int) -> Vector2:
	var center_x = (game_variant.board_data.board_size.x + 1 - file) * square_size - square_size / 2
	var center_y = rank * square_size - square_size / 2
	return Vector2(center_x, center_y)

func get_board_square_at_position(global_pos: Vector2) -> Vector2i:
	var local = board.to_local(global_pos)
	var file = board.board_size.x - int(floor(local.x / square_size))
	var rank = int(floor(local.y / square_size)) + 1
	if file < 1 or file > board.board_size.x or rank < 1 or rank > board.board_size.y:
		return Vector2i(-1, -1)

	return Vector2i(file, rank)

func is_inside_board(move: Vector2i) -> bool:
	return(move.x > 0 and move.x <= board.board_size.x and move.y > 0 and move.y <= board.board_size.y)

func is_space_taken(move: Vector2i, exclude_instance_id := -1) -> bool:
	for piece_info in pieces_on_board:
		if piece_info.instance_id == exclude_instance_id:
			continue
		if piece_info.position == move:
			return true
	return false

func get_piece_texture(piece: PieceBase, piece_owner: Player) -> Texture:
		for texture_set in game_variant.piece_sets:
				if texture_set == active_piece_set:
						for texture_info in texture_set.piece_set:
								if texture_info.piece_type == piece:
										if texture_info.owner == piece_owner or texture_info.owner == PieceTexture.Player.Both:
												return texture_info.texture
		return null

func _is_space_taken_in_state(pos: Vector2i, state: Array[PieceInfo]) -> bool:
		for info in state:
				if info.position == pos:
						return true
		return false

func _piece_threatens_king_in_state(piece_info: PieceInfo, king_pos: Vector2i, state: Array[PieceInfo]) -> bool:
		var piece_base = piece_info.piece_base
		var swing_attack_vectors = []
		var stamp_attack_vectors = []
		if piece_info.owner == Player.Sente:
				swing_attack_vectors = attack_cache["Sente"]["swinging"].get(piece_base.fen_char, [])
				stamp_attack_vectors = attack_cache["Sente"]["stamp"].get(piece_base.fen_char, [])
		else:
				swing_attack_vectors = attack_cache["Gote"]["swinging"].get(piece_base.fen_char, [])
				stamp_attack_vectors = attack_cache["Gote"]["stamp"].get(piece_base.fen_char, [])

		for direction in stamp_attack_vectors:
				var attack_position = piece_info.position + direction
				if attack_position == king_pos:
						return true

		for direction in swing_attack_vectors:
				var target_position = piece_info.position + direction
				while is_inside_board(target_position):
						if target_position == king_pos:
								return true
						if _is_space_taken_in_state(target_position, state):
								break
						target_position += direction
		return false

func _is_king_in_check_from_state(board_state: Array[PieceInfo], player: Player) -> bool:
		var king_positions: Array[Vector2i] = []
		for info in board_state:
				if info.owner == player and info.piece_base.is_royal:
						king_positions.append(info.position)
		var opponent = Player.Gote if player == Player.Sente else Player.Sente
		for king_pos in king_positions:
				for info in board_state:
						if info.owner == opponent:
								if _piece_threatens_king_in_state(info, king_pos, board_state):
										return true
		return false

func simulate_move_puts_king_in_check(piece: BaseGamePiece, move: Vector2i) -> bool:
		var temp_state: Array[PieceInfo] = []
		for info in pieces_on_board:
				var copy := PieceInfo.new()
				copy.position = info.position
				copy.owner = info.owner
				copy.piece_type = info.piece_type
				copy.piece_base = info.piece_base
				copy.instance_id = info.instance_id
				temp_state.append(copy)
		var moving_id = piece.get_instance_id()
		var captured_index := -1
		for i in range(temp_state.size()):
				var info = temp_state[i]
				if info.instance_id == moving_id:
						info.position = move
				elif info.position == move:
						captured_index = i
		if captured_index != -1:
				temp_state.remove_at(captured_index)
		return _is_king_in_check_from_state(temp_state, piece.piece_owner)
