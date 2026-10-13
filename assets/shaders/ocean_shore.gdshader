shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float game_time = 0.0;
void fragment(){
	vec2 p = (UV-0.5)*2.0;
	float a=atan(p.y,p.x);
	float radius = length(p)/(1.0+0.075*sin(a*3.0)+0.045*cos(a*5.0));
	float wave = sin(radius*85.0-game_time*1.4+sin(p.x*16.0)*0.5)*0.5+0.5;
	float band = smoothstep(0.58,0.7,radius)*(1.0-smoothstep(0.74,0.98,radius));
	ALBEDO = mix(vec3(0.12,0.78,0.76),vec3(0.9,1.0,0.95),pow(wave,8.0));
	ALPHA = band*0.32;
}
