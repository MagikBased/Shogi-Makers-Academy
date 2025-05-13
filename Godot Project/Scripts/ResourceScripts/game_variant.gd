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
@export var board_data: BoardResource
@export var turn_phases: Array[TurnPhase]
@export var pieces: Array[PieceBase]
@export var win_conditions: Array[WinConditions]
@export var starting_fen: String
@export var debug_fen: String
@export var in_hand_pieces: bool
@export var piece_sets: Array[PieceSet]
