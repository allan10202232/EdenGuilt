shader_type canvas_item;
render_mode unshaded;
uniform sampler2D world_screen : hint_screen_texture, repeat_disable, filter_nearest;
uniform float bleaching : hint_range(0.0, 1.0) = 0.0;
uniform bool protect_signals = false;
void fragment() {
	vec4 source = texture(world_screen,SCREEN_UV);
	float grey = dot(source.rgb,vec3(0.299,0.587,0.114));
	vec3 dry = vec3(grey)*vec3(1.03,1.0,0.92);
	dry = (dry-vec3(0.5))*0.86+vec3(0.56);
	float chroma = max(source.r,max(source.g,source.b))-min(source.r,min(source.g,source.b));
	float readable = protect_signals ? smoothstep(0.3,0.5,chroma)*0.82 : 0.0;
	COLOR = vec4(mix(source.rgb,dry,bleaching*0.86*(1.0-readable)),1.0);
}
