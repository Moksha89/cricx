shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform bool turf = false;
varying vec3 world_position;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void vertex() {world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment() {
 vec2 p=world_position.xz;
 float grain=noise(p*95.0)*0.5+noise(p*21.0)*0.25+noise(p*3.0)*0.25;
 if(turf) {
  float patch=noise(p*0.65);
  ALBEDO=mix(vec3(0.055,0.095,0.025),vec3(0.20,0.27,0.08),grain*0.65+patch*0.35);
 } else {
  float wear=1.0-smoothstep(0.1,1.45,abs(p.x));
  float scratch=pow(noise(vec2(p.x*90.0,p.y*9.0)),5.0);
  ALBEDO=mix(vec3(0.25,0.16,0.08),vec3(0.58,0.43,0.25),grain*0.70+wear*0.30)-scratch*0.055;
 }
 ROUGHNESS=0.96;
 SPECULAR=0.12;
}
