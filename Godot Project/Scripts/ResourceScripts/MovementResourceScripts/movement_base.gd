extends Resource
class_name MovementBase

enum MoveRestriction {
	NONE,
	CAPTURE_ONLY,
	MOVE_ONLY
}

@export var restriction: MoveRestriction = MoveRestriction.NONE
