extends Resource
class_name GameVariant

enum WinConditions{
	CHECKMATE,
	KING_CAPTURE,
	NUMBER_OF_CHECKS	
}

@export var game_name: String
@export var board_size: Vector2
@export var pieces: Array[PieceResource]
@export var win_condition: WinConditions = WinConditions.CHECKMATE
