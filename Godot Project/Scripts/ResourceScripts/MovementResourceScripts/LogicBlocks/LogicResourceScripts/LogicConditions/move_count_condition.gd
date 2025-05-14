extends LogicCondition
class_name MoveCountCondition

enum ComparisonType { EQUAL, LESS_THAN, GREATER_THAN }

@export var comparison: ComparisonType = ComparisonType.EQUAL
@export var value: int = 0

func evaluate(context: LogicContext) -> bool:
	var count = context.piece_instance.move_count

	match comparison:
		ComparisonType.EQUAL:
			return count == value
		ComparisonType.LESS_THAN:
			return count < value
		ComparisonType.GREATER_THAN:
			return count > value
	return false
