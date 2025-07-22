shader_type canvas_item;

uniform vec2 border_threshold = vec2(0.01, 0.01);
uniform int blur_strength = 3;

bool is_on_border(sampler2D tex, vec2 uv) {
	vec4 color_up = texture(tex, uv + vec2(0.0, border_threshold.y));
	vec4 color_down = texture(tex, uv - vec2(0.0, border_threshold.y));
	vec4 color_left = texture(tex, uv - vec2(border_threshold.x, 0.0));
	vec4 color_right = texture(tex, uv + vec2(border_threshold.x, 0.0));

	bool is_next_to_transparent = color_up.a < 1.0 || color_down.a < 1.0 ||
	                              color_left.a < 1.0 || color_right.a < 1.0;
	bool is_next_to_solid = color_up.a >= 1.0 || color_down.a >= 1.0 ||
	                        color_left.a >= 1.0 || color_right.a >= 1.0;

	return is_next_to_transparent && is_next_to_solid;
}

vec4 blur_color(sampler2D tex, vec2 uv) {
	vec4 sum = vec4(0.0);
	int count = 0;

	for (int x = -blur_strength; x <= blur_strength; x++) {
		for (int y = -blur_strength; y <= blur_strength; y++) {
			vec2 offset = vec2(float(x), float(y)) * border_threshold;
			sum += texture(tex, uv + offset);
			count++;
		}
	}
	return sum / float(count);
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	if (is_on_border(TEXTURE, UV)) {
		COLOR = blur_color(TEXTURE, UV);
	} else {
		COLOR = color;
	}
}
