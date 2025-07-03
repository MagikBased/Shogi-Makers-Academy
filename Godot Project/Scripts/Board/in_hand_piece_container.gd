extends Node2D
class_name InHandContainer

@export var player: InHandManager.Player
@export var square_size: float = 64.0
@export var max_height: float = 400.0
@export var columns: int = 1
@export var h_separation: float = 4.0
@export var v_separation: float = 4.0

#func _ready() -> void:
	#arrange_children()

func arrange_children() -> void:
	var x_offset = 0.0
	var y_offset = 0.0
	var row_height = square_size + v_separation
	var column_width = square_size + h_separation
	var num_children = get_child_count()
	var current_column = 0
	for i in range(num_children):
		var child = get_child(i)
		if child is InHandPiece:
			child.position = Vector2(x_offset, y_offset)
			x_offset += column_width
			current_column += 1
			if current_column >= columns or y_offset + row_height > max_height:
				x_offset = 0
				y_offset += row_height
				current_column = 0
