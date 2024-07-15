extends Sprite2D
class_name BaseGamePiece

enum Player{
	Sente,
	Gote
}

@export var piece_resource: PieceBase
var game_manager: GameManager
@onready var selection_highlight = $SelectionHighlight
var selection_color: Color = Color(0,1,0,0.5)
@onready var rect_size:Vector2
@export var current_position: Vector2i
var piece_owner = Player.Sente
var is_promoted: bool
var can_promote: bool
var selected: bool = false
var dragging: bool = false
var piece_scale: float = 1
var valid_moves: Array[Vector2i]

var square_highlight = load("res://Scenes/GameBoardScenes/square_highlight.tscn")

func _ready() -> void:
	initialize_values()
	var scale_factor = game_manager.square_size / texture.get_size().x
	scale *= scale_factor
	snap_to_grid()
	if piece_owner == Player.Gote:
		rotation_degrees += 180

func _input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed() and (piece_owner == game_manager.player_turn) and event.button_index == MOUSE_BUTTON_LEFT and game_manager.is_promoting == false:
		if get_rect().has_point(to_local(event.position)):
			selected = !selected
			if !selected:
				destroy_all_highlights()
				game_manager.selected_piece = null
			else:
				if game_manager.selected_piece != null:
					game_manager.selected_piece.destroy_all_highlights()
					game_manager.selected_piece.selected = false
				game_manager.selected_piece = self
				generate_moves()
				for move in valid_moves:
					var highlight: SquareHighlight = square_highlight.instantiate() as SquareHighlight
					highlight.current_position = move
					var board_position: Vector2 = (current_position - highlight.current_position) * (highlight.texture.get_width())
					if piece_owner == Player.Sente:
						board_position.y *= -1
					highlight.position = board_position
					highlight.connect("move_piece", Callable(self, "_on_move_piece"))
					add_child(highlight)
		queue_redraw()

func initialize_values() -> void:
	if piece_resource:
		if piece_resource.icon.size() > 0:
			texture = piece_resource.icon[0]
		is_promoted = piece_resource.is_promoted
		can_promote = piece_resource.can_promote
	rect_size = Vector2(texture.get_width(),texture.get_height())

func snap_to_grid() -> void:
	var file: int = int(current_position.x)
	var rank: int = int(current_position.y)
	var new_position: Vector2i = game_manager.find_square_center(file, rank)
	position = new_position

func destroy_all_highlights() -> void:
	for child in get_children():
		if child.is_in_group("highlight"):
			child.queue_free()

func generate_moves() -> void:
	valid_moves.clear()
	for move in piece_resource.moves:
		if move is SwingMove:
			handle_swinging_moves(move)
		elif move is StampMove:
			handle_stamp_moves(move)

func handle_stamp_moves(move:StampMove) -> void:
	for direction in move.move_directions:
		if piece_owner == Player.Gote:
			direction = Vector2i(direction.x, -direction.y)
		var target_position = current_position + direction
		if check_move_legality(target_position) and not is_space_an_ally(target_position):
			if target_position not in valid_moves:
				valid_moves.append(target_position)

func handle_swinging_moves(move: SwingMove) -> void:
	var direction = move.move_direction
	if piece_owner == Player.Gote:
		direction = Vector2i(direction.x, -direction.y)
	var max_distance = move.max_distance
	var target_position = current_position + direction
	var distance = 0
	while check_move_legality(target_position) and (max_distance == -1 or distance < max_distance):
		if is_space_an_ally(target_position):
			break
		if target_position not in valid_moves:
			valid_moves.append(target_position)
		if can_capture(target_position):
			break
		target_position += direction
		distance += 1

func check_move_legality(move: Vector2i) -> bool:
	if !is_inside_board(move):
		return false
	if can_capture(move):
		return true
	return true

func can_capture(move: Vector2i) -> bool:
	for piece_info in game_manager.pieces_on_board:
		if piece_info.position == move and piece_info.owner != piece_owner:
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

func _draw() -> void:
	if selected:
		$SelectionHighlight.visible = true
	else:
		$SelectionHighlight.visible = false
	draw_texture(texture,Vector2(float(-texture.get_width())/2,float(-texture.get_height())/2),modulate)

func _on_move_piece(move_position: Vector2i) -> void:
	var piece_info: PieceInfo = null
	for piece in game_manager.pieces_on_board:
		if piece.instance_id == game_manager.selected_piece.get_instance_id():
			piece_info = piece
			break
	if piece_info == null:
		return
	piece_info.position = move_position
	if can_capture(move_position):
		capture_piece(move_position)
	current_position = move_position
	snap_to_grid()

func capture_piece(capture_position: Vector2i) -> void:
	for i in range(game_manager.pieces_on_board.size()):
		if game_manager.pieces_on_board[i].position == capture_position:
			var captured_piece_info: PieceInfo = game_manager.pieces_on_board[i]
			var captured_piece_instance := instance_from_id(captured_piece_info.instance_id)
			if captured_piece_instance:
				captured_piece_instance.queue_free()
			game_manager.pieces_on_board.remove_at(i)
			if game_manager.game_variant.in_hand_pieces and game_manager.in_hand_manager != null and captured_piece_info.piece_base.fen_char_piece_to_add_on_capture:
				game_manager.in_hand_manager.add_piece_to_hand(InHandManager.Player.Sente if captured_piece_info.owner == Player.Gote else InHandManager.Player.Gote, captured_piece_info.piece_base)
				print(game_manager.in_hand_manager.sente_in_hand)
			break
