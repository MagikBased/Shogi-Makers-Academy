extends Node2D
class_name DebugManager

var game_manager: GameManager
var highlight_data: Dictionary = {}  # Vector2i -> Array[Color]

func _ready() -> void:
	pass

func add_highlights(positions: Array[Vector2i], color: Color) -> void:
	for pos in positions:
		if highlight_data.has(pos):
			highlight_data[pos].append(color)
		else:
			highlight_data[pos] = [color]
	
	queue_redraw()

func clear_highlights() -> void:
	highlight_data.clear()
	queue_redraw()


func _draw() -> void:
	if not game_manager:
		return
	var board = game_manager.board
	if not board:
		return

	draw_set_transform_matrix(board.get_global_transform())
	var board_size = board.board_size
	var square_size = board.square_size

	for pos in highlight_data.keys():
		var colors: Array = highlight_data[pos]
		if colors.is_empty():
			continue

		var x_index = board_size.x - pos.x
		var y_index = pos.y - 1

		var center = Vector2(
			(x_index * square_size) - 1 + 0.5 * square_size,
			(y_index * square_size) - 1 + 0.5 * square_size
		)
		var radius = square_size * 0.25

		var segment_angle = TAU / float(colors.size())
		var start_angle = -PI / 4 

		for i in range(colors.size()):
			var base_color = colors[i]
			var color = Color(base_color.r, base_color.g, base_color.b, 0.6)
			var angle_a = start_angle + i * segment_angle
			var angle_b = start_angle + (i + 1) * segment_angle

			var points = [center]
			var point_count = 32
			for j in range(point_count + 1):
				var t = float(j) / float(point_count)
				var angle = lerp(angle_a, angle_b, t)
				var p = center + Vector2(cos(angle), sin(angle)) * radius
				points.append(p)

			draw_colored_polygon(points, color)
