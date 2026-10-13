shader_type spatial;
uniform sampler2D palette : source_color, filter_nearest;
varying float height;
void vertex(){ height = VERTEX.y; }
void fragment(){
	vec3 color = texture(palette,UV).rgb;
	if(color.b > color.r * 1.12 && color.b > color.g * 1.05){
		float shade = max(color.r,max(color.g,color.b));
		color = (height > 1.45 ? vec3(0.9,0.24,0.12) : vec3(0.95,0.68,0.12)) * shade;
	}
	ALBEDO = color;
	ROUGHNESS = 0.4;
}
