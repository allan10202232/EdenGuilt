shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec4 pigment=texture(TEXTURE,UV)*COLOR;
	float edges=smoothstep(0.0,.08,UV.x)*(1.0-smoothstep(.92,1.0,UV.x));
	float dissolve=1.0-smoothstep(.30,.97,UV.y);
	COLOR=vec4(pigment.rgb,pigment.a*edges*dissolve);
}
