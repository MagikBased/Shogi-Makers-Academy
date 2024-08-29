extends Node2D
class_name  GameManager

enum Player{
	Sente,
	Gote,
	Neutral
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

func _ready() -> void:
	initialize_values()
	if game_variant.debug_fen.strip_edges() != "":
		fen_manager.create_board_from_fen(game_variant.debug_fen)
	else:
		fen_manager.create_board_from_fen(game_variant.starting_fen)
	initialize_attack_cache()
	start_phase()

func initialize_values() -> void:
	square_size = (board.texture.get_width()) / float(board.board_size.x)
	current_phase = game_variant.turn_phases[0]

func start_phase() -> void:
	#print("Starting phase: ", current_phase.phase_name)
	current_action_count = 0
	clear_constrained_moves()
	for piece_info in pieces_on_board:
		var piece_instance = instance_from_id(piece_info.instance_id) as BaseGamePiece
		if piece_instance:
			piece_instance.valid_moves = piece_instance.generate_moves()
	if game_variant.win_conditions.has(GameVariant.WinConditions.CHECKMATE) or game_variant.win_conditions.has(GameVariant.WinConditions.NUMBER_OF_CHECKS):
		var king_position = find_kings(player_turn)[0]
		determine_pins(king_position, player_turn)
		var checking_pieces = determine_checks(king_position, player_turn)
		if checking_pieces.size() > 0:
			constrain_moves_due_to_check(king_position, checking_pieces)

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
	#print("Player Turn: ", player_turn)
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

func get_piece_attack_vectors(piece_base: PieceBase, player: Player, move_type: String) -> Array:
	var attack_vectors = []
	for move in piece_base.moves:
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
					constrain_moves(piece_in_path, path)
					potential_pins.append(piece_in_path)
	#print("potential pins: " + str(potential_pins))
	return potential_pins

func determine_checks(king_position: Vector2i, player: Player) -> Array[PieceInfo]:
	var opponent = Player.Gote if player == Player.Sente else Player.Sente
	var checking_pieces: Array[PieceInfo] = []
	for piece_info in pieces_on_board:
		if piece_info.owner == opponent:
			if piece_threatens_king(piece_info, king_position):
				checking_pieces.append(piece_info)
	return checking_pieces

func constrain_moves(piece_info: PieceInfo, constrained_moves: Array[Vector2i]) -> void:
	var piece_instance = instance_from_id(piece_info.instance_id) as BaseGamePiece
	if piece_instance:
		var legal_constrained_moves: Array[Vector2i] = []
		for move in piece_instance.valid_moves:
			#print(piece_instance.valid_moves)
			if move in constrained_moves:
				legal_constrained_moves.append(move)
		for move in legal_constrained_moves:
					if not piece_instance.constrained_moves.has(move):
						piece_instance.constrained_moves.append(move)
		#piece_instance.valid_moves = legal_constrained_moves.duplicate()

func constrain_moves_due_to_check(king_position: Vector2i, checking_pieces: Array[PieceInfo]) -> void:
	for piece_info in pieces_on_board:
		if piece_info.owner == player_turn:
			var piece_instance = instance_from_id(piece_info.instance_id) as BaseGamePiece
			if piece_instance:
				var legal_constrained_moves: Array[Vector2i] = []
				var piece_moves = piece_instance.valid_moves
				#print(piece_moves)
				for move in piece_instance.valid_moves:
					if piece_info.piece_base.is_royal:
						var safe_move = true
						for checking_piece in checking_pieces:
							if piece_threatens_king(checking_piece, move):
								safe_move = false
								break
						if safe_move:
							legal_constrained_moves.append(move)
					else:
						for checking_piece in checking_pieces:
							if move == checking_piece.position:
								legal_constrained_moves.append(move)
							elif is_blocking_move_valid(king_position, move, checking_piece):
								legal_constrained_moves.append(move)
				for move in legal_constrained_moves:
					if not piece_instance.constrained_moves.has(move):
						piece_instance.constrained_moves.append(move)

func is_blocking_move_valid(king_position: Vector2i, move: Vector2i, attacking_piece_info: PieceInfo) -> bool:
	var direction = (king_position - attacking_piece_info.position)
	var blocking_position = attacking_piece_info.position + direction
	print(direction)
	while blocking_position != king_position:
		if blocking_position == move:
			return true
		blocking_position += direction
	return false

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
			piece_instance.constrained_moves.clear()

func get_piece_info_at_position(board_position: Vector2i) -> PieceInfo:
	for piece_info in pieces_on_board:
		if piece_info.position == board_position:
			return piece_info
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

func set_variant(game_varient: GameVariant) -> void:
	game_variant = game_varient

#func get_current_phase(turn_count: int) -> TurnPhase:
	#return turn_phases[(turn_count - 1) % turn_phases.size()]

func find_square_center(file: int,rank: int) -> Vector2:
	var center_x = (game_variant.board_data.board_size.x + 1 - file) * square_size - square_size / 2
	var center_y = rank * square_size - square_size / 2
	return Vector2(center_x, center_y)

func _input(event):
	if event is InputEventKey and event.pressed:
		#print(determine_pins(find_kings(Player.Sente)[0], Player.Sente))
		#print(determine_pins(find_kings(Player.Gote)[0], Player.Gote))
		#print(find_kings(Player.Sente)[0])
		pass

func is_inside_board(move: Vector2i) -> bool:
	return(move.x > 0 and move.x <= board.board_size.x and move.y > 0 and move.y <= board.board_size.y)

func is_space_taken(move: Vector2i) -> bool:
	for piece_info in pieces_on_board:
		if piece_info.position == move:
			return true
	return false
