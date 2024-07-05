shader_type canvas_item;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	float red_threshold = 0.75;
	float non_red_threshold = 0.61;

	if (original_color.r > red_threshold && original_color.g < non_red_threshold && original_color.b < non_red_threshold) {
		COLOR = original_color;
	} else {
		COLOR = original_color * vec4(0.85, 0.85, 0.85, 1.0);
	}
}
