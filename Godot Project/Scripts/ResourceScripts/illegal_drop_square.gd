extends Resource
class_name IllegalDropSquare

enum Player {
	Sente,
	Gote,
	Both
}

@export var player: Player
@export var move_position: Vector2i
