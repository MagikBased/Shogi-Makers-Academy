extends RefCounted
class_name PieceInfo

enum Player{
	Sente,
	Gote
}

@export var position: Vector2
@export var owner: Player
@export var piece_type: String
@export var instance_id: int
