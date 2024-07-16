extends Sprite2D
class_name InHandPiece

@export var piece_resource: PieceBase
@export var player: InHandManager.Player
var square_size: float

func _ready() -> void:
	if piece_resource:
		if piece_resource.icon.size() > 0:
			texture = piece_resource.icon[0]
	#print(square_size)
	scale *= square_size / texture.get_size().x
