extends Node2D
class_name InHandManager

enum Player{
	Sente,
	Gote
}
var game_variant: GameVariant
var sente_in_hand: Dictionary = {}
var gote_in_hand: Dictionary = {}

func _ready():
	for piece in game_variant.pieces:
		if piece.fen_char_piece_to_add_on_capture and not sente_in_hand.has(piece.fen_char_piece_to_add_on_capture):
			sente_in_hand[piece.fen_char] = 0
			gote_in_hand[piece.fen_char.to_lower()] = 0

func add_piece_to_hand(player: Player, piece: PieceBase) -> void:
	if player == Player.Sente:
		sente_in_hand[piece.fen_char_piece_to_add_on_capture] += 1
	elif player == Player.Gote:
		gote_in_hand[piece.fen_char_piece_to_add_on_capture] += 1

func remove_piece_from_hand(player: Player, piece: PieceBase) -> void: #Consider making this a bool
	if player == Player.Sente and sente_in_hand[piece.fen_char] > 0:
		sente_in_hand[piece.fen_char] -= 1
	elif player == Player.Gote and gote_in_hand[piece.fen_char] > 0:
		gote_in_hand[piece.fen_char] -= 1

func reset_in_hand_pieces() -> void:
	for key in sente_in_hand.keys():
		sente_in_hand[key] = 0
	for key in gote_in_hand.keys():
		gote_in_hand[key] = 0
