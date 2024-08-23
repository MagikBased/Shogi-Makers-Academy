extends Node2D

signal promotion_selected(piece_base:PieceBase)

@export var piece_base: PieceBase
@onready var sprite = $Sprite2D

func _ready() -> void:
	if piece_base:
		sprite.texture = piece_base.icon[0]

func _input(event) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("promotion_selected", piece_base)
		queue_free()
