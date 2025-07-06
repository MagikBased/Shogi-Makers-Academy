extends Node2D
class_name PortableGameNotation

@onready var move_slider = $MoveSlider
@onready var move_label = $MoveLabel

var game_manager: GameManager
var history: Array[String] = []

func _ready() -> void:
	move_slider.min_value = 0
	move_slider.max_value = 0
	move_slider.step = 1
	move_slider.value = 0

func add_sfen(sfen: String) -> void:
	history.append(sfen)
	move_slider.max_value = history.size() - 1
	move_slider.value = history.size() - 1
	_update_label(int(move_slider.value))

func _on_move_slider_value_changed(value: float) -> void:
	_update_label(int(value))
	_set_board_to_index(int(value))

func _set_board_to_index(index: int) -> void:
	if index < 0 or index >= history.size():
		return
	var sfen = history[index]
	game_manager.fen_manager.create_board_from_fen(sfen)
	game_manager.allow_input = index == history.size() - 1

func _update_label(index: int) -> void:
	if move_label:
		move_label.text = "Move " + str(index + 1)
