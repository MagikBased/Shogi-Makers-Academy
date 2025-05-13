extends Resource
class_name PieceTexture

enum Player
{
	Sente,
	Gote,
	Nuetral,
	Both,
}

@export var set_id: String
@export var owner: GameManager.Player = GameManager.Player.Both
@export var texture: Texture
@export var piece_type: PieceBase
