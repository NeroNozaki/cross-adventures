shader_type canvas_item;
uniform vec4 tanques[8];
uniform int quantidade = 0;
varying vec2 mundo;
void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	vec2 p = floor(mundo / 2.0) * 2.0;
	float profundidade = 0.0;
	for (int i = 0; i < quantidade; i++) {
		vec2 inicio = tanques[i].xy;
		vec2 fim = inicio + tanques[i].zw;
		if (all(greaterThanEqual(p, inicio)) && all(lessThanEqual(p, fim))) {
			vec2 distancia = min(p - inicio, fim - p);
			profundidade = max(profundidade, min(distancia.x, distancia.y));
		}
	}
	float tempo = floor(TIME * 8.0) / 8.0;
	float onda = sin(p.x * 0.06 + p.y * 0.035 + tempo * 0.65);
	float reflexo = sin(p.x * 0.11 - p.y * 0.045 - tempo * 0.38);
	vec3 margem = vec3(0.19, 0.38, 0.43);
	vec3 fundo = vec3(0.065, 0.19, 0.27);
	vec3 agua = mix(margem, fundo, smoothstep(0.0, 30.0, profundidade));
	agua += floor((onda + reflexo) * 1.5) * 0.008;
	float filete = step(0.987, sin(p.x * 0.04 + p.y * 0.19 + tempo * 0.38));
	agua += vec3(0.10, 0.17, 0.17) * filete * smoothstep(5.0, 15.0, profundidade) * 0.4;
	agua *= mix(0.62, 1.0, smoothstep(0.0, 7.0, profundidade));
	COLOR = vec4(agua, 1.0);
}
