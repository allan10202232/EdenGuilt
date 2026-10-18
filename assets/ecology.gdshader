shader_type canvas_item;
render_mode unshaded;
uniform sampler2D world_screen : hint_screen_texture, repeat_disable, filter_nearest;
uniform float bleaching : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 source = texture(world_screen,SCREEN_UV);
	float grey = dot(source.rgb,vec3(0.299,0.587,0.114));
	// Dry vegetation, without lowering the scene's exposure or crushing shadows.
	// Include muted olive foliage, not just the brightest green leaves.
	float green = smoothstep(-0.06,0.14,source.g-source.r) * smoothstep(0.01,0.16,source.g-source.b);
	vec3 straw = vec3(0.87,0.66,0.20) * (grey / 0.67);
	vec3 dry = mix(source.rgb,straw,green*0.96);
	// Amber pollution shifts the whole palette; retain saturation and exposure.
	dry = dry*vec3(1.10,1.0,0.72)+vec3(0.035,0.014,0.0);
	float dry_luma = dot(dry,vec3(0.299,0.587,0.114));
	dry *= (grey+0.015)/max(dry_luma,0.015);
	COLOR = vec4(mix(source.rgb,clamp(dry,0.0,1.0),bleaching),1.0);
}
