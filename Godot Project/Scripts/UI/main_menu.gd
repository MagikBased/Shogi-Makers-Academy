extends Control
class_name MainMenu

@onready var game_room_scene = preload("res://Scenes/GameBoardScenes/game_room.tscn")

var sente_option: OptionButton
var gote_option: OptionButton

enum PlayerType {
	Human,
	AI,
}

func _ready() -> void:
	var vbox := VBoxContainer.new()
	add_child(vbox)

	var sente_hbox := HBoxContainer.new()
	vbox.add_child(sente_hbox)
	var sente_label := Label.new()
	sente_label.text = "Sente:"
	sente_hbox.add_child(sente_label)
	sente_option = OptionButton.new()
	sente_option.add_item("Human", PlayerType.Human)
	sente_option.add_item("AI", PlayerType.AI)
	sente_hbox.add_child(sente_option)

	var gote_hbox := HBoxContainer.new()
	vbox.add_child(gote_hbox)
	var gote_label := Label.new()
	gote_label.text = "Gote:"
	gote_hbox.add_child(gote_label)
	gote_option = OptionButton.new()
	gote_option.add_item("Human", PlayerType.Human)
	gote_option.add_item("AI", PlayerType.AI)
	gote_hbox.add_child(gote_option)

	var start_button := Button.new()
	start_button.text = "Start Game"
	start_button.pressed.connect(_on_start_game_pressed)
	vbox.add_child(start_button)

func _on_start_game_pressed() -> void:
	var game_room := game_room_scene.instantiate() as GameRoom
	game_room.sente_player_type = PlayerType(sente_option.get_selected_id())
	game_room.gote_player_type = PlayerType(gote_option.get_selected_id())
	get_tree().root.add_child(game_room)
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	get_tree().current_scene = game_room
