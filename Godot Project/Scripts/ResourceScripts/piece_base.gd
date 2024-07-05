extends Resource
class_name PieceBase

@export var piece_name: String
@export var fen_char: String
@export var icon: Array[Texture]
@export var is_royal: bool
@export var moves: Array[MovementBase]

@export_category("Promotion")
@export var can_promote: bool
@export var is_promoted: bool
@export var promotes_to: Array[PieceBase]
