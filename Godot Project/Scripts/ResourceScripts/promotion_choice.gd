extends Node2D

signal promotion_selected(piece_base:PieceBase)

@export var piece_base: PieceBase
@onready var sprite = $Sprite2D
var corner_radius: float = 20.0

func _ready() -> void:
	if piece_base:
		sprite.texture = piece_base.icon[0]

func _input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if sprite.get_rect().has_point(to_local(event.position)):
			emit_signal("promotion_selected", piece_base)
			queue_free()

func _draw() -> void:
	if sprite.texture:
		var rect_size = sprite.texture.get_size() #+ Vector2(rect_padding * 2, rect_padding * 2)
		var rect_position = -rect_size / 2
		draw_style_box(get_stylebox(), Rect2(rect_position, rect_size))

func get_stylebox() -> StyleBoxFlat:
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_box.set_border_width_all(2)
	style_box.border_color = Color(1, 1, 1)
	style_box.corner_radius_top_left = corner_radius
	style_box.corner_radius_top_right = corner_radius
	style_box.corner_radius_bottom_left = corner_radius
	style_box.corner_radius_bottom_right = corner_radius
	return style_box
