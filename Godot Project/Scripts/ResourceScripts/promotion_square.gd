extends Resource
class_name PromotionSquare

enum Player {
	Sente,
	Gote,
	Both
}

@export var player: Player
@export var position: Vector2i
@export var forced_promotion: bool = false
