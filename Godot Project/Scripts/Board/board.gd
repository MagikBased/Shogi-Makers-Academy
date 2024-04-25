extends Sprite2D

@export var board_data: BoardResource
var board_size: Vector2 = Vector2(9, 9)
var line_size: int = 8  # should be divisible by 4 for even lines
var square_size: float
var circle_radius: float
var start_x: float
var start_y: float
var spacing_x: float
var spacing_y: float
var grid_color: Color = Color(0, 0, 0)
var circle_color: Color = Color(0, 0, 0)
var x_margin: float = 25
var font_size: int = 80
var font_color: Color = Color(0, 0, 0)
var font: Font

func _ready():
	initialize_values()

func initialize_values() -> void:
	square_size = texture.get_width() / board_size.x
	circle_radius = square_size * 0.15
	start_x = square_size / 2
	start_y = square_size / 2
	spacing_x = square_size
	spacing_y = square_size

func _draw():
	draw_grid()
	font = ThemeDB.fallback_font
	var char_size = font.get_string_size("1", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	for x in range(board_size.x):
		var number = str(board_size.x - x)
		draw_string(font, Vector2(start_x + (x * spacing_x) - (char_size.x / 2), start_y - spacing_y / 2 - (spacing_y / 10)), number, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, font_color)

	for y in range(board_size.y):
		var number = str(y + 1)
		draw_string(font, Vector2(texture.get_width() + start_x - (spacing_x / 2) + (spacing_x / 10), start_y + (char_size.y / 4) + (y * spacing_y)), number, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, font_color)

func draw_grid() -> void:
	for x in range(1, board_size.x):
		var x_position = x * square_size
		draw_line(Vector2(x_position, 0), Vector2(x_position, square_size * board_size.y), grid_color, line_size)
	for y in range(1, board_size.y):
		var y_position = y * square_size
		draw_line(Vector2(0, y_position), Vector2(square_size * board_size.x, y_position), grid_color, line_size)
	
	draw_circle(Vector2(square_size * 3, square_size * 3), circle_radius, circle_color)
	draw_circle(Vector2(square_size * 3, square_size * 6), circle_radius, circle_color)
	draw_circle(Vector2(square_size * 6, square_size * 3), circle_radius, circle_color)
	draw_circle(Vector2(square_size * 6, square_size * 6), circle_radius, circle_color)
