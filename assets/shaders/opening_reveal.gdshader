shader_type canvas_item;
render_mode unshaded;

// A stable reveal order lets the same image dissolve cleanly on the way out.
uniform float visibility : hint_range(0.0, 1.0) = 0.0;
uniform vec2 pixel_grid = vec2(384.0, 216.0);
uniform float chapter_seed = 0.0;
uniform bool soft_fade = false;

float pixel_order(vec2 cell) {
	return fract(sin(dot(cell + chapter_seed, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 artwork = texture(TEXTURE, UV);
	float coverage;
	if (soft_fade) {
		coverage = visibility;
	} else {
		vec2 cell = floor(UV * pixel_grid);
		coverage = step(pixel_order(cell), visibility);
		if (visibility <= 0.0) coverage = 0.0;
		if (visibility >= 1.0) coverage = 1.0;
	}
	COLOR = vec4(artwork.rgb, artwork.a * coverage);
}
