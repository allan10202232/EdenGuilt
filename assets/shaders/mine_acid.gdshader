shader_type canvas_item;
render_mode unshaded;
uniform float clock = 0.0;
varying vec2 water_position;

float random_at(vec2 point) {
	return fract(sin(dot(point,vec2(127.1,311.7)))*43758.5453);
}

float water_noise(vec2 point) {
	vec2 cell=floor(point);
	vec2 weight=fract(point);
	weight=weight*weight*(3.0-2.0*weight);
	return mix(mix(random_at(cell),random_at(cell+vec2(1.0,0.0)),weight.x),mix(random_at(cell+vec2(0.0,1.0)),random_at(cell+vec2(1.0)),weight.x),weight.y);
}

void vertex() {
	water_position=VERTEX;
}

void fragment() {
	vec2 pixel=floor(water_position/2.0)*2.0;
	float flow=water_noise(pixel*vec2(.016,.028)+vec2(clock*.12,-clock*.08));
	float shimmer=water_noise(pixel*vec2(.055,.065)+vec2(-clock*.23,clock*.05));
	float depth=clamp(pixel.y/320.0,0.0,1.0);
	vec3 deep=vec3(.025,.075,.018);
	vec3 surface=vec3(.055,.19,.025);
	vec3 water=mix(surface,deep,depth*.84);
	water+=vec3(.035,.065,.012)*flow*.8;
	float ribbon=smoothstep(.70,.86,flow+shimmer*.19);
	water=mix(water,vec3(.21,.37,.04),ribbon*(1.0-depth)*.28);
	COLOR=vec4(water,1.0);
}
