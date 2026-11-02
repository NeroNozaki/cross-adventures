shader_type canvas_item;
render_mode blend_mix;
uniform sampler2D profundidade : filter_linear, repeat_disable;
uniform vec2 tamanho_grade;
varying vec2 mapa;
void vertex(){mapa=VERTEX;}
float ruido(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 p=floor(mapa/2.0)*2.0;
 float d=max(texture(profundidade,(p/32.0+vec2(1.0))/tamanho_grade).r*8.0-0.5,0.0);
 vec3 rasa=vec3(0.16,0.40,0.43);
 vec3 funda=vec3(0.055,0.19,0.27);
 vec3 cor=mix(rasa,funda,smoothstep(0.0,4.0,d));
 float onda=sin(p.x*0.032+sin(p.y*0.048+TIME*0.32)*1.7+TIME*0.38);
 float onda2=sin(p.y*0.065+sin(p.x*0.023-TIME*0.22)*1.6-TIME*0.5);
 float caustica=step(0.91,onda*onda2)*0.025*(1.0-smoothstep(1.0,5.0,d));
 float detalhe=(floor(ruido(floor(p/4.0))*3.0)-1.0)*0.007;
 cor+=vec3(detalhe+caustica);
 cor*=mix(0.65,1.0,smoothstep(0.0,0.38,d));
 COLOR=vec4(cor,1.0);
}
