extends Node2D
class_name SelectionHighlight

@onready var selection_color: Color = get_parent().selection_color
var rect_size: Vector2 = Vector2(100,100)
var piece_moved: bool = false
var moved_from: Vector2i

func _ready():
	call_deferred("set_rect_size")

func set_rect_size():
	rect_size = get_parent().rect_size

func _draw():
	draw_rect(Rect2(Vector2(0,0) - rect_size/2,rect_size),selection_color,true)
