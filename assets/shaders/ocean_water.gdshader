shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
uniform float game_time = 0.0;
varying vec3 world_pos;
void vertex() {
    world_pos = VERTEX;
    float x=VERTEX.x; float z=VERTEX.z; float t=game_time;
    VERTEX.y += sin(x*1.1+z*0.5+t*1.2)*0.045 + sin(z*1.8-x*0.25-t*0.85)*0.035;
    float dx=cos(x*1.1+z*0.5+t*1.2)*0.0495-cos(z*1.8-x*0.25-t*0.85)*0.00875;
    float dz=cos(x*1.1+z*0.5+t*1.2)*0.0225+cos(z*1.8-x*0.25-t*0.85)*0.063;
    NORMAL=normalize(vec3(-dx,1.0,-dz));
}
void fragment() {
    vec2 p=world_pos.xz;
    float t=game_time;
    float broad=0.5+0.5*sin(p.x*0.13+p.y*0.21);
    float a=sin(p.x*4.1+p.y*2.8+t*1.1);
    float b=sin(p.y*5.2-p.x*1.8-t*0.9);
    float caustic=pow(1.0-abs(a*0.5+b*0.5),22.0);
    ALBEDO=mix(vec3(0.025,0.38,0.43),vec3(0.055,0.59,0.59),broad);
    float glint=pow(max(0.0,sin(p.y*6.0+sin(p.x*3.0+t)*0.8-t*1.4)),32.0);
    glint*=pow(max(0.0,sin(p.x*2.8+sin(p.y*1.9)+t*0.7)),4.0);
    ALBEDO+=vec3(0.08,0.13,0.12)*glint;
    EMISSION=vec3(0.10,0.3,0.27)*caustic*0.10;
    NORMAL_MAP=vec3(0.5+a*0.09,0.5+b*0.09,1.0);
    NORMAL_MAP_DEPTH=0.65;
    ROUGHNESS=0.19;
    METALLIC=0.18;
    SPECULAR=0.75;
    ALPHA=0.57;
}
