extends Sprite2D
class_name SquareHighlight

var current_position: Vector2i
var is_dropping: bool = false
var parent_node: Node2D
signal move_piece(position: Vector2i)
signal drop_piece(position: Vector2i)

@export var normal_color: Color = Color(1, 1, 1, 1)
@export var hover_color: Color = Color(0, 0, 1, 1)

var is_hovered := false

@export var special_command: SpecialMoveCommand

func _ready() -> void:
	parent_node = get_parent() as BaseGamePiece
	set_process_input(true)

func _input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and get_rect().has_point(to_local(event.position)):
		if special_command != null:
			var context := LogicContext.new()
			context.piece_instance = parent_node
			context.game_state = parent_node.game_manager
			context.additional_data = { "highlight_position": current_position }
			special_command.execute(context)
		else:
			if is_dropping:
				emit_signal("drop_piece", current_position)
			else:
				emit_signal("move_piece", current_position)

func set_hovered(is_hovering: bool) -> void:
	modulate = hover_color if is_hovering else normal_color
