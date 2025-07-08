extends Sprite2D
class_name BoardSquareMarker

var game_manager: GameManager
var board_pos: Vector2i

func set_board_position(pos: Vector2i) -> void:
	board_pos = pos
	if not game_manager:
		return
	var board := game_manager.board
	z_index = board.z_index + 1
