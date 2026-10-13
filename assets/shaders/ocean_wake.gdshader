shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float game_time = 0.0;
void fragment(){
	float along = UV.y;
	float width = 0.12 + (1.0-along)*0.34;
	float side = abs(UV.x-0.5);
	float band = 1.0-smoothstep(0.025,0.09,abs(side-width));
	float ripple = 0.55+0.45*sin(along*48.0+game_time*8.0+UV.x*7.0);
	ALBEDO = vec3(0.75,0.96,0.98);
	ALPHA = band*ripple*smoothstep(0.0,0.2,along)*0.65;
}
