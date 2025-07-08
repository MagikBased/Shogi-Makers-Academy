extends Sprite2D
class_name BoardSquareMarker

var game_manager: GameManager
var board_pos: Vector2i

func set_board_position(pos: Vector2i) -> void:
	board_pos = pos
	if not game_manager:
		return
	var board := game_manager.board
	var square_size := game_manager.square_size
	var pos_vec := game_manager.find_square_center(pos.x, pos.y)
	position = pos_vec
	scale = Vector2.ONE * (square_size / texture.get_width())
	z_index = board.z_index + 1
