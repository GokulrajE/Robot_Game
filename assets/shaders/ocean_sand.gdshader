shader_type spatial;
varying vec3 p;
void vertex() { float a=atan(VERTEX.z,VERTEX.x); VERTEX.xz*=1.0+0.075*sin(a*3.0)+0.045*cos(a*5.0); p = VERTEX; }
void fragment() {
    float grain = fract(sin(dot(p.xz,vec2(127.1,311.7)))*43758.5453);
    float ripple = sin(p.x*22.0+sin(p.z*11.0)*0.65)*0.016;
    ALBEDO = vec3(0.69,0.59,0.40) + (grain-0.5)*0.045 + ripple;
    ROUGHNESS = 0.94;
}
