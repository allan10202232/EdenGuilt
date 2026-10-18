shader_type canvas_item;
render_mode unshaded;

uniform float clock = 0.0;
varying vec2 water_position;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise_at(vec2 p) {
	vec2 cell = floor(p);
	vec2 weight = smoothstep(vec2(0.0), vec2(1.0), fract(p));
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), weight.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), weight.x), weight.y);
}

void vertex() {
	water_position = VERTEX;
}

void fragment() {
	vec2 pixel = floor(water_position / 3.0) * 3.0;
	float depth = clamp(pixel.y / 240.0, 0.0, 1.0);
	float current = noise_at(pixel * vec2(0.014, 0.035) + vec2(clock * 0.2, -clock * 0.1));
	float detail = noise_at(pixel * vec2(0.07, 0.09) + vec2(-clock * 0.3, clock * 0.08));
	vec3 water = mix(vec3(0.19, 0.29, 0.10), vec3(0.035, 0.07, 0.04), depth);
	water += vec3(0.055, 0.075, 0.015) * current;
	float streak = smoothstep(0.66, 0.88, current + detail * 0.2);
	water += vec3(0.12, 0.16, 0.035) * streak * (1.0 - depth) * 0.5;
	COLOR = vec4(water, 1.0);
}
