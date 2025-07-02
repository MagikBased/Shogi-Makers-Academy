extends Node2D
class_name BaseGamePiece

enum Player{
	Sente,
	Gote,
	Neutral,
	Both
}

@export var piece_resource: PieceBase
var game_manager: GameManager
@onready var selection_highlight = $SelectionHighlight
@onready var piece_sprite = $PieceSprite
var selection_color: Color = Color(0,1,0,0.5)
@onready var rect_size:Vector2
@export var current_position: Vector2i
var piece_owner = Player.Sente
var is_promoted: bool
var can_promote: bool
var selected: bool = false
var dragging: bool = false
var drag_sprite: Sprite2D
var drag_start_square: Vector2i
var piece_scale: float = 1
var valid_moves: Array[Vector2i]
var constrained_moves: Array[Vector2i] = []
var pending_handle_action := false
var is_fully_constrained: bool = false

var square_highlight = load("res://Scenes/GameBoardScenes/square_highlight.tscn")

var special_logic_blocks: Array[LogicBlock]
var extra_generated_moves: Array[MovementBase] = []
var move_count: int = 0

func _ready() -> void:
	initialize_values()
	var scale_factor = game_manager.square_size / piece_sprite.texture.get_size().x
	scale *= scale_factor
	snap_to_grid()
	if piece_owner == Player.Gote:
		rotation_degrees += 180

func _input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and piece_owner == game_manager.player_turn and game_manager.is_promoting == false:
			if event.is_pressed() and piece_sprite.get_rect().has_point(to_local(event.position)):
					if !selected:
							if game_manager.selected_piece != null:
									game_manager.selected_piece.destroy_all_highlights()
									game_manager.selected_piece.set_selected(false)
							set_selected(true)
							game_manager.selected_piece = self
							valid_moves = generate_moves()
							for move in valid_moves:
									var highlight: SquareHighlight = square_highlight.instantiate() as SquareHighlight
									highlight.current_position = move
									var board_position: Vector2 = (current_position - highlight.current_position) * highlight.texture.get_width()
									if piece_owner == Player.Sente:
											board_position.y *= -1
									if piece_owner == Player.Gote:
											board_position.x *= -1
									highlight.position = board_position
									highlight.connect("move_piece", Callable(self, "_on_move_piece"))
									add_child(highlight)
					dragging = true
					drag_start_square = current_position
					drag_sprite = Sprite2D.new()
					drag_sprite.texture = piece_sprite.texture
					drag_sprite.scale = scale
					drag_sprite.rotation = rotation
					drag_sprite.z_index = z_index + 100
					game_manager.board.add_child(drag_sprite)
					drag_sprite.position = game_manager.board.to_local(event.position)
					piece_sprite.modulate.a = 0.5
					queue_redraw()
			elif !event.is_pressed() and dragging:
					dragging = false
					piece_sprite.modulate.a = 1.0
					if drag_sprite:
							drag_sprite.queue_free()
							drag_sprite = null
					var drop_square = game_manager.get_board_square_at_position(event.position)
					if drop_square == drag_start_square:
							pass
					elif drop_square in valid_moves:
							_on_move_piece(drop_square)
					else:
							destroy_all_highlights()
							set_selected(false)
							game_manager.selected_piece = null
					queue_redraw()
	elif event is InputEventMouseMotion and dragging:
			drag_sprite.position = game_manager.board.to_local(event.position)

func initialize_values() -> void:
	if piece_resource:
		var assigned_texture = game_manager.get_piece_texture(piece_resource, piece_owner)
		if assigned_texture:
			piece_sprite.texture = assigned_texture
		elif piece_resource.icon.size() > 0:
			piece_sprite.texture = piece_resource.icon[0]
		is_promoted = piece_resource.is_promoted
		can_promote = piece_resource.can_promote
		special_logic_blocks = piece_resource.logic_blocks
	rect_size = Vector2(piece_sprite.texture.get_width(),piece_sprite.texture.get_height())

func snap_to_grid() -> void:
	var file: int = int(current_position.x)
	var rank: int = int(current_position.y)
	var new_position: Vector2i = game_manager.find_square_center(file, rank)
	position = new_position

func destroy_all_highlights() -> void:
	for child in get_children():
		if child.is_in_group("highlight"):
			child.queue_free()

func generate_moves() -> Array[Vector2i]:
	valid_moves.clear()
	if is_fully_constrained:
		return valid_moves
	evaluate_special_logic_blocks()
	if constrained_moves.size() > 0:
		for move in constrained_moves:
			if is_inside_board(move) and not is_space_an_ally(move):
				valid_moves.append(move)
	else:
		for move in piece_resource.moves:
			if move is SwingMove:
				handle_swinging_moves(move)
			elif move is StampMove:
				handle_stamp_moves(move)
		for move in extra_generated_moves:
			if move is SwingMove:
				handle_swinging_moves(move)
			elif move is StampMove:
				handle_stamp_moves(move)
	return valid_moves

func evaluate_special_logic_blocks() -> void:
	extra_generated_moves.clear()
	for block in special_logic_blocks:
		var context := LogicContext.new()
		context.game_state = game_manager
		context.piece_instance = self
		context.additional_data = {}
		if block.can_execute(context):
			block.execute(context)

func handle_stamp_moves(move: StampMove) -> void:
	for direction in move.move_directions:
		if piece_owner == Player.Gote:
			direction = -direction
		var target_position = current_position + direction
		if check_move_legality(target_position, move.restriction):
			if target_position not in valid_moves:
				valid_moves.append(target_position)

func handle_swinging_moves(move: SwingMove) -> void:
	var direction = move.move_direction
	if piece_owner == Player.Gote:
		direction = Vector2i(-direction.x, -direction.y)
	var max_distance = move.max_distance
	var target_position = current_position + direction
	var distance = 0
	while is_inside_board(target_position) and (max_distance == -1 or distance < max_distance):
		if not check_move_legality(target_position, move.restriction):
			break
		if is_space_an_ally(target_position):
			break
		if target_position not in valid_moves:
			valid_moves.append(target_position)
		if can_capture(target_position) and move.restriction != MovementBase.MoveRestriction.MOVE_ONLY:
			break
		target_position += direction
		distance += 1

func capture_piece(capture_position: Vector2i) -> void:
	for i in range(game_manager.pieces_on_board.size()):
		if game_manager.pieces_on_board[i].position == capture_position:
			#print(game_manager.pieces_on_board[i].piece_type)
			var captured_piece_info: PieceInfo = game_manager.pieces_on_board[i]
			var captured_piece_instance := instance_from_id(captured_piece_info.instance_id)
			#print(captured_piece_info.owner)
			game_manager.pieces_on_board.remove_at(i)
			if captured_piece_instance:
				captured_piece_instance.queue_free()
			if game_manager.game_variant.in_hand_pieces and game_manager.in_hand_manager != null and captured_piece_info.piece_base.fen_char_piece_to_add_on_capture:
				game_manager.in_hand_manager.add_piece_to_hand(InHandManager.Player.Sente if captured_piece_info.owner == Player.Gote else InHandManager.Player.Gote, captured_piece_info.piece_base)
			break

func check_move_legality(move: Vector2i, restriction := MovementBase.MoveRestriction.NONE) -> bool:
	if not is_inside_board(move):
		return false
	return check_move_restriction(move, restriction)

func check_move_restriction(move: Vector2i, restriction: MovementBase.MoveRestriction) -> bool:
	var is_taken = is_space_taken(move)
	var is_ally = is_space_an_ally(move)
	match restriction:
		MovementBase.MoveRestriction.CAPTURE_ONLY:
			return is_taken and not is_ally
		MovementBase.MoveRestriction.MOVE_ONLY:
			return not is_taken
		MovementBase.MoveRestriction.NONE:
			return not is_ally
	return false

func can_capture(move: Vector2i) -> bool:
	for piece_info in game_manager.pieces_on_board:
		if piece_info.position == move and piece_info.owner != piece_owner:
			return true
	return false

func can_promote_check(start_position: Vector2i, move_position: Vector2i) -> bool:
	if not can_promote:
		return false
	for promotion_square in piece_resource.promotion_squares:
		if promotion_square.player != PromotionSquare.Player.Both and promotion_square.player != piece_owner:
			continue
		var in_start = promotion_square.position == start_position
		var in_end = promotion_square.position == move_position
		match promotion_square.promotion_move_rule:
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

func is_inside_board(move: Vector2i) -> bool:
	return(move.x > 0 and move.x <= game_manager.board.board_size.x and move.y > 0 and move.y <= game_manager.board.board_size.y)

func is_space_taken(move: Vector2i) -> bool:
	for piece_info in game_manager.pieces_on_board:
		if piece_info.position == move:
			return true
	return false

func is_space_an_ally(move: Vector2i) -> bool:
	for piece_info in game_manager.pieces_on_board:
		if piece_info.position == move and piece_info.owner == piece_owner:
			return true
	return false

func get_promotion_square(square_position: Vector2i) -> PromotionSquare:
	for promotion_square in piece_resource.promotion_squares:
		if promotion_square.position == square_position and (promotion_square.player == PromotionSquare.Player.Both or promotion_square.player == piece_owner):
			return promotion_square
	return null

func apply_promotion() -> void:
	if piece_resource.promotes_to.size() > 0:
		piece_resource = piece_resource.promotes_to[0] #needs to extend this to check what piece the forced promotion is.
		is_promoted = true
		if piece_resource.icon.size() > 0:
			piece_sprite.texture = piece_resource.icon[0]
		#texture = piece_resource.icon[0]
		for piece_info in game_manager.pieces_on_board:
			if piece_info.instance_id == get_instance_id():
				piece_info.piece_base = piece_resource
				piece_info.piece_type = piece_resource.fen_char
				break

func show_promotion_choice() -> void:
	game_manager.is_promoting = true
	var options_parent = Node2D.new()
	add_child(options_parent)
	var promotion_option_scene = load("res://Scenes/GameBoardScenes/promotion_choice.tscn")
	var x_offset = 0
	var center_position = Vector2.ZERO
	for i in range(piece_resource.promotes_to.size()):
		var promotion_base = piece_resource.promotes_to[i]
		var promotion_option = promotion_option_scene.instantiate() as Node2D
		promotion_option.piece_base = promotion_base
		var position_offset = Vector2()
		if i % 2 == 0:
			position_offset.x = x_offset * (game_manager.square_size / scale.x)
		else:
			x_offset += 1
			position_offset.x = -x_offset * (game_manager.square_size / scale.x)
		promotion_option.position = center_position + position_offset
		promotion_option.connect("promotion_selected", Callable(self, "_on_promotion_selected"))
		options_parent.add_child(promotion_option)
	var no_promotion_option = promotion_option_scene.instantiate() as Node2D
	no_promotion_option.piece_base = piece_resource
	var no_promotion_position_offset = Vector2(0, game_manager.square_size / scale.y)
	no_promotion_option.position = center_position + no_promotion_position_offset
	no_promotion_option.get_child(0).texture = piece_sprite.texture
	no_promotion_option.connect("promotion_selected", Callable(self, "_on_promotion_selected"))
	options_parent.add_child(no_promotion_option)

func set_selected(value: bool) -> void:
	selected = value
	selection_highlight.visible = selected

func _on_move_piece(move_position: Vector2i) -> void:
	move_count += 1
	var piece_info: PieceInfo = null
	var coming_from_square:= current_position
	for piece in game_manager.pieces_on_board:
		if piece.instance_id == game_manager.selected_piece.get_instance_id():
			piece_info = piece
			break
	if piece_info == null:
		return
	if can_capture(move_position):
		capture_piece(move_position)
	piece_info.position = move_position
	current_position = move_position
	destroy_all_highlights()
	snap_to_grid()
	if can_promote_check(coming_from_square, move_position):
		var promotion_square: PromotionSquare = get_promotion_square(move_position)
		if promotion_square and promotion_square.forced_promotion:
			apply_promotion()
		else:
			pending_handle_action = true
			show_promotion_choice()
			return
	finalize_action()

func finalize_action() -> void:
	if game_manager.handle_action(piece_resource.fen_char, TurnAction.ActionType.MovePiece):
		game_manager.selected_piece = null
		set_selected(false)
		queue_redraw()

func _on_promotion_selected(selected_piece_base: PieceBase) -> void:
	var options_parent = get_child(get_child_count() - 1)
	options_parent.queue_free()
	game_manager.is_promoting = false
	if selected_piece_base != piece_resource and selected_piece_base != null:
		apply_promotion()
		piece_resource = selected_piece_base
		scale = Vector2.ONE * (game_manager.square_size / piece_sprite.texture.get_size().x)
		snap_to_grid()
	if pending_handle_action:
		pending_handle_action = false
		finalize_action()
