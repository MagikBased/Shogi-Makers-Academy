extends Resource
class_name GameVariant

enum WinConditions{
	CHECKMATE,
	KING_CAPTURE,
	NUMBER_OF_CHECKS,
	GET_PIECE_TO_SQUARE,
	PROMOTE_PIECE
}

@export var game_name: String
@export var board_size: Vector2
@export var pieces: Array[PieceBase]
@export var win_condition: WinConditions = WinConditions.CHECKMATE
@export var starting_fen: String
