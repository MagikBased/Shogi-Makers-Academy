extends "res://Scripts/ResourceScripts/MovementResourceScripts/LogicBlocks/LogicResourceScripts/LogicEffects/special_move_command.gd"
class_name DoubleStepCommand

func execute(context: LogicContext) -> void:
	if context.piece_instance == null:
		return
	var position: Vector2i = context.additional_data.get("highlight_position", Vector2i.ZERO)
	context.piece_instance._on_move_piece(position)
