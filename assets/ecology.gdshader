shader_type canvas_item;
uniform float bleaching : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 source = COLOR;
	float grey = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(source.rgb, vec3(grey * 1.12 + 0.04), bleaching), source.a);
}
