extends Resource
class_name PieceBase

@export var piece_name: String
@export var fen_char: String
@export var game_variant: Resource
@export var icon: Texture
@export var moves: Array[MovementBase]
@export var can_promote: bool
@export var is_promoted: bool
@export var promotes_to: Array[PieceBase]
