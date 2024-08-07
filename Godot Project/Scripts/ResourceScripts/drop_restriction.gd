extends Resource
class_name DropRestriction

enum OwnershipType {
	Allied,
	Opponent,
	Both
}

@export var piece_type: String
@export var ownership_type: OwnershipType = OwnershipType.Allied
@export var count: int = 1
@export var check_rank: bool = false
@export var check_file: bool = false
