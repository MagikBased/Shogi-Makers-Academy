extends Sprite2D
class_name BaseGamePiece

enum Player{
	Sente,
	Gote
}

@export var piece_resource: PieceBase
var game_manager: GameManager
@export var current_position: Vector2
var piece_owner = Player.Sente
var is_promoted: bool
var can_promote: bool
var selected: bool = false
var dragging: bool = false
var piece_scale: float = 1
var valid_moves: Array[Vector2]

func _ready():
	initialize_values()
	var scale_factor = game_manager.square_size / texture.get_size().x
	scale *= scale_factor
	snap_to_grid()
	if piece_owner == Player.Gote:
		rotation_degrees += 180

func initialize_values():
	if piece_resource:
		if piece_resource.icon.size() > 0:
			texture = piece_resource.icon[0]
		is_promoted = piece_resource.is_promoted
		can_promote = piece_resource.can_promote
		
func snap_to_grid() -> void:
	var file: int = int(current_position.x)
	var rank: int = int(current_position.y)
	var new_position: Vector2 = game_manager.find_square_center(file, rank)
	position = new_position
