extends GridContainer
class_name InHandContainer

@export var player: InHandManager.Player
@export var square_size: float = 64
@export var max_height: float = 400
@export var h_separation: int = 4
@export var v_separation: int = 4

func _ready() -> void:
	set_columns(1)
	set("custom_constants/h_separation", h_separation)
	set("custom_constants/v_separation", v_separation)
	set_custom_minimum_size(Vector2(square_size, square_size))
	
	
func adjust_size() -> void:
	var num_children: int = get_child_count()
	var num_rows: int = ceil(float(num_children) / columns) 
	var container_height = num_rows * square_size + (num_rows - 1) * v_separation
	if container_height > max_height:
		columns += 1
		adjust_size()
	else:
		var container_width = columns * square_size + (columns - 1) * h_separation
		custom_minimum_size = Vector2(container_width, container_height)
