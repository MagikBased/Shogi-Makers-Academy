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
