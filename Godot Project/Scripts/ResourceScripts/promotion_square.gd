extends Resource
class_name PromotionSquare

enum Player {
	Sente,
	Gote,
	Both
}
enum PromotionMove {
	MovesInto,
	MovesOutOf,
	Both
}

@export var player: Player
@export var position: Vector2i
@export var forced_promotion: bool = false
@export var promotion_move_rule: PromotionMove = PromotionMove.Both
