class_name LogicBlock
extends Resource

@export var name: String
@export var conditions: Array[LogicCondition] = []
@export var effects: Array[LogicEffect] = []

func can_execute(context: LogicContext) -> bool:
	for condition in conditions:
		if not condition.evaluate(context):
			return false
	return true

func execute(context: LogicContext) -> void:
	for effect in effects:
		effect.apply(context)
