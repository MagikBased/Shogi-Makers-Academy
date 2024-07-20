extends Sprite2D
class_name InHandPiece

@export var piece_resource: PieceBase
@export var player: InHandManager.Player
var game_manager: GameManager
@onready var count_label = $PieceCount
@onready var selection_highlight = $SelectionHighlight
var selection_color: Color = Color(0,1,0,0.5)
@onready var rect_size:Vector2
var square_size: float
var selected: bool = false

func _ready() -> void:
	if piece_resource:
		if piece_resource.icon.size() > 0:
			texture = piece_resource.icon[0]
	scale *= square_size / texture.get_size().x

func is_inside_board(move: Vector2i) -> bool:
	return(move.x > 0 and move.x <= game_manager.board.board_size.x and move.y > 0 and move.y <= game_manager.board.board_size.y)

func is_space_taken(move: Vector2i) -> bool:
	for piece_info in game_manager.pieces_on_board:
		if piece_info.position == move:
			return true
	return false

func update_alpha(count: int) -> void:
	self.modulate.a = 1.0 if count > 0 else 0.3
	count_label.text = str(count)
	#var label_size = count_label.get_rect().size
	count_label.position = Vector2(texture.get_width() / 4.0, texture.get_height() / 4.0)
	count_label.z_index = self.z_index + 1

func _draw() -> void:
	if selected:
		$SelectionHighlight.visible = true
	else:
		$SelectionHighlight.visible = false
	draw_texture(texture,Vector2(float(-texture.get_width())/2,float(-texture.get_height())/2),modulate)
