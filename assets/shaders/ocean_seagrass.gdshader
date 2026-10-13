shader_type spatial;
render_mode cull_disabled;
uniform float game_time = 0.0;
void vertex() {
    float tip=1.0-UV.y;
    VERTEX.x*=0.12+0.88*UV.y;
    VERTEX.x+=sin(game_time*0.8+VERTEX.y*3.0)*tip*tip*0.16;
}
void fragment() {
    ALBEDO=mix(vec3(0.055,0.21,0.16),vec3(0.25,0.52,0.30),1.0-UV.y);
    ROUGHNESS=0.85;
}
