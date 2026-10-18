shader_type canvas_item;
render_mode unshaded;

uniform float depletion : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float grey = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 dead_soil = vec3(grey * 0.64 + 0.07, grey * 0.58 + 0.045, grey * 0.51 + 0.03);
	float foliage = smoothstep(0.015, 0.12, source.g - max(source.r, source.b));
	COLOR = vec4(mix(source.rgb, dead_soil, depletion), source.a * (1.0 - foliage * depletion * 0.30));
}
