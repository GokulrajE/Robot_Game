shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 glow_color : source_color = vec4(0.2, 0.8, 1.0, 0.3);
void fragment() {
	float radius = length(UV - vec2(0.5)) * 2.0;
	float falloff = pow(1.0 - smoothstep(0.0, 1.0, radius), 2.0);
	ALBEDO = glow_color.rgb;
	ALPHA = glow_color.a * falloff;
}
