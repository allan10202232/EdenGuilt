shader_type canvas_item;
render_mode unshaded;

uniform vec2 cells = vec2(6.0,4.0);
uniform vec2 logical_pixels = vec2(96.0);
uniform vec4 ambient : source_color = vec4(0.95,1.0,0.78,1.0);
uniform float flash : hint_range(0.0,1.0) = 0.0;
uniform float energy : hint_range(0.0,1.0) = 0.0;
uniform vec4 energy_tint : source_color = vec4(1.0,0.38,0.18,1.0);
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec2 grid = cells * logical_pixels;
	vec2 uv = (floor(UV * grid) + vec2(0.5)) / grid;
	vec4 texel = texture(TEXTURE, uv);
	// Remove faint baked halos and keep the silhouette on a shared pixel grid.
	float alpha = step(0.24, texel.a) * texel.a;
	vec2 local_uv = fract(UV * cells);
	float shade = floor(clamp(local_uv.y,0.0,0.99)*4.0)/3.0;
	vec3 pigment = floor(texel.rgb*24.0+0.5)/24.0;
	vec3 lit = pigment * mix(vec3(1.0),ambient.rgb,0.28) * (1.04 - shade*0.10);
	float core = max(0.0,1.0-length((local_uv-vec2(0.58,0.62))*vec2(3.0,4.0)));
	lit += energy_tint.rgb * energy * core * 0.24;
	lit = mix(lit,vec3(1.0,0.98,0.85),flash*0.85);
	// Fragment COLOR already includes the original texture: use vertex tint
	// so quantized sampling and flash do not multiply the sprite a second time.
	COLOR = vec4(lit,alpha) * vertex_tint;
}
