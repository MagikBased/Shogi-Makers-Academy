extends Sprite2D
class_name SquareHighlight

var current_position: Vector2i
var is_dropping: bool = false
var parent_node: Node2D
signal move_piece(position: Vector2i)
signal drop_piece(position: Vector2i)


func _ready() -> void:
	parent_node = get_parent() as BaseGamePiece
	set_process_input(true)

func _input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and get_rect().has_point(to_local(event.position)):
		emit_signal("drop_piece", current_position)
		emit_signal("move_piece", current_position)
