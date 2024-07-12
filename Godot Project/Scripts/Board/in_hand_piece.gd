extends Node2D
class_name InHandPiece

@export var piece_resource: PieceBase
@export var player: InHandManager.Player
@onready var sprite_2d = $Sprite2D

func _ready() -> void:
	if piece_resource.icon.size() > 0:
		$Sprite2D.texture = piece_resource.icon[0]
