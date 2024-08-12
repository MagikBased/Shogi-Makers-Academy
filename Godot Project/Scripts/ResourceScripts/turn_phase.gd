extends Resource
class_name TurnPhase

enum Player {
	Sente,
	Gote
}

@export var phase_name: String
@export var player: Player
@export var actions: Array[TurnAction] = []
@export var max_actions_per_turn: int = 1
