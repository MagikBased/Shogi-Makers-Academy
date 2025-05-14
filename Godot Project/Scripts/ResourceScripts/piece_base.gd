extends Resource
class_name PieceBase

@export var piece_name: String
@export var fen_char: String
@export var icon: Array[Texture]
@export var is_royal: bool
@export var moves: Array[MovementBase]
@export var logic_blocks: Array[LogicBlock]

@export_category("Promotion")
@export var can_promote: bool
@export var is_promoted: bool
@export var promotes_to: Array[PieceBase]
@export var promotion_squares: Array[PromotionSquare] = []
@export_category("Capture")
@export var can_add_to_hand: bool
@export var fen_char_piece_to_add_on_capture: String

@export_category("Drop Rules")
@export var can_deliver_checkmate: bool = true
@export var illegal_drop_squares: Array[IllegalDropSquare] = []
@export var drop_restrictions: Array[DropRestriction] = []
