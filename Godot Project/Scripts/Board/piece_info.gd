extends RefCounted
class_name PieceInfo

enum Player{
	Sente,
	Gote
}

@export var position: Vector2i
@export var owner: Player
@export var piece_type: String
@export var piece_base: PieceBase
@export var instance_id: int
