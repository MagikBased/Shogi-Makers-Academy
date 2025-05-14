extends LogicEffect
class_name AddMovementEffect

@export var movement: MovementBase

func apply(context: LogicContext) -> void:
	if not context.piece_instance or not movement:
		return

	var movement_copy = movement.duplicate()
	context.piece_instance.extra_generated_moves.append(movement_copy)
