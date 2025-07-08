extends Node
class_name AlphaBetaAI

var game_manager: GameManager
var search_depth: int = 2

func play_turn(player: GameManager.Player) -> void:
	var move = choose_move(player)
	print("AI selected move: ", move)
	if move == null:
		return
	if move.has('drop_piece_base'):
		var hand_player = InHandManager.Player.Sente if player == GameManager.Player.Sente else InHandManager.Player.Gote
		game_manager.in_hand_manager.remove_piece_from_hand(hand_player, move.drop_piece_base)
		game_manager.create_piece(move.drop_piece_base, move.to, player)
		game_manager.handle_action(move.drop_piece_base.fen_char, TurnAction.ActionType.DropPiece)
		game_manager.record_move()
	else:
		var piece_instance = instance_from_id(move.piece_id) as BaseGamePiece
		if piece_instance:
			print("AI moving piece id", move.piece_id, "to", move.to)
			game_manager.selected_piece = piece_instance
			piece_instance.set_selected(true)
			piece_instance._on_move_piece(move.to)

func choose_move(player: GameManager.Player) -> Dictionary:
	var state = _create_state()
	var result = _alpha_beta(state, search_depth, -INF, INF, player, player)
	print("AI choose_move result: ", result)
	return result.get('move')

func _create_state() -> Dictionary:
	var s := {}
	s.pieces = []
	for info in game_manager.pieces_on_board:
		var c := PieceInfo.new()
		c.position = info.position
		c.owner = info.owner
		c.piece_type = info.piece_type
		c.piece_base = info.piece_base
		c.instance_id = info.instance_id
		s.pieces.append(c)
	s.sente_hand = game_manager.in_hand_manager.sente_in_hand.duplicate() if game_manager.in_hand_manager else {}
	s.gote_hand = game_manager.in_hand_manager.gote_in_hand.duplicate() if game_manager.in_hand_manager else {}
	return s

func _alpha_beta(state: Dictionary, depth: int, alpha: float, beta: float, current_player: GameManager.Player, maximizing: GameManager.Player) -> Dictionary:
	if depth == 0 or _is_game_over(state):
		return {'score': _evaluate_state(state, maximizing)}
	
	var best_move
	
	if current_player == maximizing:
		var value = -INF
		for move in _generate_all_moves(state, current_player):
			var new_state = _apply_move(state, move)
			if _is_in_check(new_state, current_player):
				continue
			var result = _alpha_beta(new_state, depth - 1, alpha, beta, _opponent(current_player), maximizing)
			if result.score > value:
				value = result.score
				best_move = move
			alpha = max(alpha, value)
			if beta <= alpha:
				break
		return {'score': value, 'move': best_move}
	else:
		var value = INF
		for move in _generate_all_moves(state, current_player):
			var new_state = _apply_move(state, move)
			if _is_in_check(new_state, current_player):
				continue
			var result = _alpha_beta(new_state, depth - 1, alpha, beta, _opponent(current_player), maximizing)
			if result.score < value:
				value = result.score
				best_move = move
			beta = min(beta, value)
			if beta <= alpha:
				break
		return {'score': value, 'move': best_move}

func _opponent(player: GameManager.Player) -> GameManager.Player:
	return GameManager.Player.Gote if player == GameManager.Player.Sente else GameManager.Player.Sente

func _is_game_over(state: Dictionary) -> bool:
	var sente = false
	var gote = false
	for info in state.pieces:
		if info.piece_base.is_royal:
			if info.owner == GameManager.Player.Sente:
				sente = true
			else:
				gote = true
	return not sente or not gote

func _evaluate_state(state: Dictionary, maximizing: GameManager.Player) -> int:
	var score = 0
	for info in state.pieces:
		var value = 1
		if info.piece_base.is_royal:
			value = 100
		if info.owner == maximizing:
			score += value
		else:
			score -= value
	return score

func _is_in_check(state: Dictionary, player: GameManager.Player) -> bool:
	var king_pos = Vector2i()
	for info in state.pieces:
		if info.owner == player and info.piece_base.is_royal:
			king_pos = info.position
			break
	var opponent = _opponent(player)
	return king_pos in _squares_attacked_by_player(state, opponent)

func _squares_attacked_by_player(state: Dictionary, player: GameManager.Player) -> Array:
	var attacked: Array[Vector2i] = []
	var player_str = "Sente" if player == GameManager.Player.Sente else "Gote"
	for info in state.pieces:
		if info.owner != player:
			continue
		var key = info.piece_base.fen_char
		var swing = game_manager.attack_cache[player_str]["swinging"].get(key, [])
		var stamp = game_manager.attack_cache[player_str]["stamp"].get(key, [])
		for dir in swing:
			var pos = info.position + dir
			while game_manager.is_inside_board(pos):
				attacked.append(pos)
				if _is_space_taken_in_state(pos, state.pieces):
					break
				pos += dir
		for dir in stamp:
			var pos = info.position + dir
			if game_manager.is_inside_board(pos):
				attacked.append(pos)
	return attacked

func _generate_all_moves(state: Dictionary, player: GameManager.Player) -> Array:
	var moves := []
	for info in state.pieces:
		if info.owner != player:
			continue
		for move_pos in _generate_moves_for_piece(info, state):
			moves.append({
				'piece_id': info.instance_id,
				'piece_base': info.piece_base,
				'from': info.position,
				'to': move_pos,
				'player': player
			})

	if game_manager.game_variant.in_hand_pieces:
		var hand: Dictionary = state.sente_hand if player == GameManager.Player.Sente else state.gote_hand
		for fen_char in hand.keys():
			if hand[fen_char] > 0:
				var piece_base = game_manager.in_hand_manager.get_piece_base_from_fen_char(
					fen_char if player == GameManager.Player.Sente else fen_char.to_lower()
				)
				for x in range(1, game_manager.board.board_size.x + 1):
					for y in range(1, game_manager.board.board_size.y + 1):
						var pos = Vector2i(x, y)
						if _is_space_taken_in_state(pos, state.pieces):
							continue
						if _illegal_drop_square(piece_base, pos, player):
							continue
						if _violates_drop_restrictions(piece_base, pos, state, player):
							continue
						if not piece_base.can_deliver_checkmate and _would_cause_checkmate(piece_base, pos, player, state):
							continue
						moves.append({
							'drop_piece_base': piece_base,
							'to': pos,
							'player': player
						})
	return moves

func _generate_moves_for_piece(info: PieceInfo, state: Dictionary) -> Array:
	var result := []
	var owner: GameManager.Player = info.owner as GameManager.Player
	for move in info.piece_base.moves:
		if move is StampMove:
			for dir in move.move_directions:
				var d = dir
				if owner == GameManager.Player.Gote:
					d = Vector2i(-dir.x, -dir.y)
				var target = info.position + d
				if not game_manager.is_inside_board(target):
					continue
				if _move_allowed(target, owner, move.restriction, state):
					result.append(target)
		elif move is SwingMove:
			var d = move.move_direction
			if owner == GameManager.Player.Gote:
				d = Vector2i(-d.x, -d.y)
			var max_dist = move.max_distance
			var target = info.position + d
			var dist = 0
			while game_manager.is_inside_board(target) and (max_dist == -1 or dist < max_dist):
				if not _move_allowed(target, owner, move.restriction, state):
					break
				result.append(target)
				if _is_space_taken_in_state(target, state.pieces):
					break
				target += d
				dist += 1
	return result

func _move_allowed(pos: Vector2i, player: GameManager.Player, restriction: MovementBase.MoveRestriction, state: Dictionary) -> bool:
	var taken = _is_space_taken_in_state(pos, state.pieces)
	var ally = _is_space_taken_by_player(pos, player, state.pieces)
	match restriction:
		MovementBase.MoveRestriction.CAPTURE_ONLY:
			return taken and not ally
		MovementBase.MoveRestriction.MOVE_ONLY:
			return not taken
		_:
			return not ally

func _apply_move(state: Dictionary, move: Dictionary) -> Dictionary:
	var new_state = {
		'pieces': [],
		'sente_hand': state.sente_hand.duplicate(),
		'gote_hand': state.gote_hand.duplicate()
	}
	for info in state.pieces:
		var c := PieceInfo.new()
		c.position = info.position
		c.owner = info.owner
		c.piece_type = info.piece_type
		c.piece_base = info.piece_base
		c.instance_id = info.instance_id
		new_state.pieces.append(c)
	if move.has('drop_piece_base'):
		var hand = new_state.sente_hand if move.player == GameManager.Player.Sente else new_state.gote_hand
		hand[move.drop_piece_base.fen_char if move.player == GameManager.Player.Sente else move.drop_piece_base.fen_char.to_lower()] -= 1
		var info = PieceInfo.new()
		info.position = move.to
		info.owner = move.player
		info.piece_base = move.drop_piece_base
		info.piece_type = move.drop_piece_base.fen_char if move.player == GameManager.Player.Sente else move.drop_piece_base.fen_char.to_lower()
		info.instance_id = -1
		new_state.pieces.append(info)
	else:
		var captured_index := -1
		for i in range(new_state.pieces.size()):
			var p = new_state.pieces[i]
			if p.position == move.from and p.instance_id == move.piece_id:
				p.position = move.to
			elif p.position == move.to:
				captured_index = i
		if captured_index != -1:
			var captured = new_state.pieces[captured_index]
			new_state.pieces.remove_at(captured_index)
			if game_manager.game_variant.in_hand_pieces and captured.piece_base.fen_char_piece_to_add_on_capture:
				var fen = captured.piece_base.fen_char_piece_to_add_on_capture
				if move.player == GameManager.Player.Sente:
					new_state.sente_hand[fen] = new_state.sente_hand.get(fen, 0) + 1
				else:
					fen = fen.to_lower()
					new_state.gote_hand[fen] = new_state.gote_hand.get(fen, 0) + 1
	return new_state

func _is_space_taken_in_state(pos: Vector2i, pieces: Array) -> bool:
	for p in pieces:
		if p.position == pos:
			return true
	return false

func _is_space_taken_by_player(pos: Vector2i, player: GameManager.Player, pieces: Array) -> bool:
	for p in pieces:
		if p.position == pos and p.owner == player:
			return true
	return false

func _illegal_drop_square(piece_base: PieceBase, pos: Vector2i, player: GameManager.Player) -> bool:
	for sq in piece_base.illegal_drop_squares:
		if sq.move_position == pos and (
			sq.player == IllegalDropSquare.Player.Both
			or (sq.player == IllegalDropSquare.Player.Sente and player == GameManager.Player.Sente)
			or (sq.player == IllegalDropSquare.Player.Gote and player == GameManager.Player.Gote)
		):
			return true
	return false

func _violates_drop_restrictions(piece_base: PieceBase, pos: Vector2i, state: Dictionary, player: GameManager.Player) -> bool:
	for restriction in piece_base.drop_restrictions:
		var rank_count = 0
		var file_count = 0
		for info in state.pieces:
			var is_allied = info.owner == player
			var is_opponent = info.owner != player
			var valid_rank = restriction.check_rank and info.position.y == pos.y
			var valid_file = restriction.check_file and info.position.x == pos.x
			var matches_type = info.piece_type == restriction.piece_type
			var matches = false
			match restriction.ownership_type:
				DropRestriction.OwnershipType.Allied:
					matches = is_allied
				DropRestriction.OwnershipType.Opponent:
					matches = is_opponent
				_:
					matches = true
			if matches and matches_type:
				if valid_rank:
					rank_count += 1
				if valid_file:
					file_count += 1
		if (restriction.check_rank and rank_count >= restriction.count) \
				or (restriction.check_file and file_count >= restriction.count):
			return true
	return false

func _would_cause_checkmate(piece_base: PieceBase, pos: Vector2i, player: GameManager.Player, state: Dictionary) -> bool:
	var move_state = _apply_move(state, {
		'drop_piece_base': piece_base,
		'to': pos,
		'player': player
	})
	var opponent = _opponent(player)
	if not _is_in_check(move_state, opponent):
		return false
	for m in _generate_all_moves(move_state, opponent):
		var new_state = _apply_move(move_state, m)
		if not _is_in_check(new_state, opponent):
			return false
	return true
