shader_type spatial;
varying vec3 p;
void vertex() {
    VERTEX *= 1.0+0.07*sin(VERTEX.x*11.0+VERTEX.z*6.0)+0.045*cos(VERTEX.y*15.0);
    p = VERTEX;
}
void fragment() {
    float grain=fract(sin(dot(p.xz,vec2(127.1,311.7)))*43758.5453);
    ALBEDO=vec3(0.40,0.43,0.39)+(grain-0.5)*0.035;
    ROUGHNESS=0.9;
}
