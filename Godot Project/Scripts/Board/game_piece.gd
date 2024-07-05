extends Sprite2D
class_name GamePiece

@export var piece_resource: PieceBase

@export var currentPosition: Vector2
var selected: bool = false

func _ready():
	if piece_resource:
		if piece_resource.icon.size() > 0:
			texture = piece_resource.icon[0]
