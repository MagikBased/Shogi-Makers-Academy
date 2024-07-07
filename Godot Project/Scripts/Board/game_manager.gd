extends Node2D
class_name  GameManager

var game_variant: GameVariant
var starting_board: String
var square_size: float
var pieces_on_board: Array[PieceInfo] = []
#var game_pieces: Array[PieceBase]

func _ready():
	initialize_values()
	#print(game_variant.pieces)
	create_piece(game_variant.pieces[0], Vector2(1,1))

func initialize_values() -> void:
	pass

func create_piece(piece_base: PieceBase, starting_position: Vector2) -> void:
	var piece_scene = load("res://Scenes/GameBoardScenes/game_piece.tscn")
	var piece = piece_scene.instantiate() as BaseGamePiece
	piece.piece_resource = piece_base
	piece.current_position = starting_position
	piece.game_manager = self
	add_child(piece)

func set_variant(game_varient: GameVariant) -> void:
	game_variant = game_varient

func find_square_center(file: int,rank: int) -> Vector2:
	print(square_size)
	var center_x = (10 - file) * square_size - square_size / 2
	var center_y = rank * square_size - square_size / 2
	#print(Vector2(center_x,center_y))
	return Vector2(center_x, center_y)
