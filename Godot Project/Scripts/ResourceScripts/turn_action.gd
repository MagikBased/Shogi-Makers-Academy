extends Resource
class_name TurnAction

enum ActionType {
	MovePiece,
	DropPiece
}

enum PiecesForAction {
	Allied,
	Neutral,
	Enemy,
	Any
}

@export var action_type: ActionType
@export var max_actions: int = 1
@export var pieces_for_action: PiecesForAction = PiecesForAction.Allied
@export var pieces_for_action_override: Array[String] = []
