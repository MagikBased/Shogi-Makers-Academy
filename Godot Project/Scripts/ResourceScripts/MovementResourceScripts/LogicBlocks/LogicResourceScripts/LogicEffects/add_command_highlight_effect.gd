extends LogicEffect
class_name AddCommandHighlightEffect

@export var command: SpecialMoveCommand
@export var move_direction: Vector2i
@export var distance: int = 1

var highlight_scene := preload("res://Scenes/GameBoardScenes/square_highlight.tscn")

func apply(context: LogicContext) -> void:
	if context.piece_instance == null or command == null:
		return
	var piece: BaseGamePiece = context.piece_instance
	var dir: Vector2i = move_direction
	if piece.piece_owner == BaseGamePiece.Player.Gote:
		dir = Vector2i(-dir.x, -dir.y)
	var target := piece.current_position
	for i in range(distance):
		target += dir
		if not piece.is_inside_board(target):
			return
		if piece.is_space_taken(target):
			return
	var highlight: SquareHighlight = highlight_scene.instantiate() as SquareHighlight
	highlight.current_position = target
	highlight.special_command = command
	var board_position: Vector2 = (piece.current_position - highlight.current_position) * highlight.texture.get_width()
	if piece.piece_owner == BaseGamePiece.Player.Sente:
		board_position.y *= -1
	if piece.piece_owner == BaseGamePiece.Player.Gote:
		board_position.x *= -1
	highlight.position = board_position
	piece.add_child(highlight)
