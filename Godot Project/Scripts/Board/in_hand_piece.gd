extends BaseGamePiece
class_name InHandPiece

#enum Player{
	#Sente,
	#Gote
#}

#@export var piece_resource: PieceBase
@export var player: InHandManager.Player
#var game_manager: GameManager
@onready var count_label = $PieceCount
#@onready var selection_highlight = $SelectionHighlight
#var selection_color: Color = Color(0,1,0,0.5)
#@onready var rect_size:Vector2
var square_size: float
#var piece_owner = Player.Sente
#var selected: bool = false
#var valid_moves: Array[Vector2i]

func _ready() -> void:
	if piece_resource:
		if piece_resource.icon.size() > 0:
			texture = piece_resource.icon[0]
	scale *= square_size / texture.get_size().x

func _input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		var local_mouse_position = to_local(event.position)
		if get_rect().has_point(local_mouse_position):
			var piece_count = game_manager.in_hand_manager.get_piece_count_in_hand(player, piece_resource.fen_char_piece_to_add_on_capture)
			if piece_owner == game_manager.player_turn and piece_count > 0 and not game_manager.is_promoting:
				selected = !selected
				if !selected:
					valid_moves = []
					destroy_all_highlights()
					game_manager.selected_piece = null
				else:
					if game_manager.selected_piece != null:
						game_manager.selected_piece.destroy_all_highlights()
						game_manager.selected_piece.selected = false
						valid_moves = []
					game_manager.selected_piece = self
					get_valid_moves()
					for moves in valid_moves:
						var global_square_size: Vector2 = Vector2(game_manager.square_size, game_manager.square_size) * game_manager.board.global_scale
						var highlight = square_highlight.instantiate()
						add_child(highlight)
						highlight.current_position = moves
						var board_position: Vector2 = game_manager.board.global_position
						board_position.x += (game_manager.board.board_size.x - moves.x) * global_square_size.x
						if piece_owner == Player.Sente:
							board_position.y += (moves.y - 1) * global_square_size.y
						elif piece_owner == Player.Gote:
							board_position.y += (game_manager.board.board_size.y - moves.y) * global_square_size.y
						highlight.global_position = board_position
						highlight.position.x += highlight.texture.get_width() / 2
						highlight.position.y +=  highlight.texture.get_height() / 2
						highlight.z_index = game_manager.board.z_index + 1

func get_valid_moves() -> void:
	valid_moves.clear()
	var board_size = game_manager.board.board_size
	for x in range(1, board_size.y + 1):
		for y in range(1, board_size.y + 1):
			var move_position = Vector2i(x,y)
			if is_inside_board(move_position) and not is_space_taken(move_position):
				if not is_illegal_drop_square(move_position):
					valid_moves.append(move_position)

func is_inside_board(move: Vector2i) -> bool:
	return(move.x > 0 and move.x <= game_manager.board.board_size.x and move.y > 0 and move.y <= game_manager.board.board_size.y)

func is_space_taken(move: Vector2i) -> bool:
	for piece_info in game_manager.pieces_on_board:
		if piece_info.position == move:
			return true
	return false

func is_illegal_drop_square(move_position: Vector2i) -> bool:
	if piece_resource.illegal_drop_squares.size() == 0:
		return false
	for illegal_square in piece_resource.illegal_drop_squares:
		if illegal_square.move_position == move_position and (illegal_square.player == IllegalDropSquare.Player.Both or illegal_square.player == piece_owner):
			return true
	return false

func update_alpha(count: int) -> void:
	self.modulate.a = 1.0 if count > 0 else 0.3
	count_label.text = str(count)
	#var label_size = count_label.get_rect().size
	count_label.position = Vector2(texture.get_width() / 4.0, texture.get_height() / 4.0)
	count_label.z_index = self.z_index + 1

func destroy_all_highlights() -> void:
	for child in get_children():
		if child.is_in_group("highlight"):
			child.queue_free()

func _draw() -> void:
	if selected:
		$SelectionHighlight.visible = true
	else:
		$SelectionHighlight.visible = false
	draw_texture(texture,Vector2(float(-texture.get_width())/2,float(-texture.get_height())/2),modulate)
