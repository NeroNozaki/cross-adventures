shader_type canvas_item;
render_mode unshaded;

varying vec4 pose;
varying vec3 luz;
varying float visor;

float distancia_elipse(vec2 ponto, vec2 centro, vec2 raio) {
	vec2 delta = (ponto - centro) / raio;
	return dot(delta, delta);
}

float halo(vec2 ponto, vec2 centro, vec2 raio) {
	return 1.0 - smoothstep(0.0, 1.0, distancia_elipse(ponto, centro, raio));
}

float apoio(vec2 ponto, vec2 centro, vec2 raio) {
	return 1.0 - smoothstep(0.48, 1.0, distancia_elipse(ponto, centro, raio));
}

void vertex() {
	pose = vec4(
		0.5 - 0.5 * cos(TIME * 2.1),
		sin(TIME * 2.5 - 1.15),
		0.5 - 0.5 * cos(TIME * 1.68 + 2.0),
		sin(TIME * 1.35 + 0.6)
	);
	visor = 1.0 - smoothstep(0.035, 0.15, abs(mod(TIME + 0.65, 5.6) - 2.0));
	luz = vec3(
		0.48 + sin(TIME * 5.5) * 0.11 + sin(TIME * 11.2) * 0.055,
		0.49 + sin(TIME * 5.1 + 1.7) * 0.12 + sin(TIME * 9.4) * 0.05,
		0.44 + sin(TIME * 1.8) * 0.19
	);
}

void fragment() {
	vec2 uv = UV;
	float cascata = halo(UV, vec2(0.36, 0.48), vec2(0.052, 0.112));
	if (UV.x < 0.31 && UV.y > 0.42 && UV.y < 0.77) {
		float cabeca = apoio(UV, vec2(0.187, 0.550), vec2(0.066, 0.100));
		float peito = apoio(UV, vec2(0.191, 0.659), vec2(0.091, 0.110));
		float tronco = max(cabeca, peito) * (1.0 - smoothstep(0.687, 0.766, UV.y));
		float ponta_capa = halo(UV, vec2(0.115, 0.704), vec2(0.042, 0.066));
		uv -= vec2(tronco * pose.x * 0.0017, tronco * pose.x * 0.0069 + ponta_capa * pose.y * 0.0045);
	} else if (UV.x > 0.71 && UV.y > 0.43 && UV.y < 0.79) {
		float capacete = apoio(UV, vec2(0.833, 0.585), vec2(0.081, 0.117));
		float armadura = apoio(UV, vec2(0.837, 0.682), vec2(0.107, 0.107));
		float tronco = max(capacete, armadura) * (1.0 - smoothstep(0.699, 0.781, UV.y));
		uv -= vec2((pose.z * 0.0012 + pose.w * 0.0020) * tronco, tronco * pose.z * 0.0064);
	} else if (cascata > 0.0) {
		uv.y += cascata * sin(floor(UV.x * 670.0) * 0.79 + UV.y * 94.0 - TIME * 12.0) * 0.002;
	}
	vec4 arte = texture(TEXTURE, uv);
	if (UV.x > 0.75 && UV.x < 0.88 && UV.y > 0.55 && UV.y < 0.74) {
		float faixa = apoio(uv, vec2(0.813, 0.604), vec2(0.038, 0.030));
		float nucleo = halo(uv, vec2(0.813, 0.696), vec2(0.023, 0.028));
		float ciano = smoothstep(0.19, 0.43, arte.b) * smoothstep(0.10, 0.29, arte.g - arte.r);
		arte.rgb *= 1.0 + ciano * (nucleo * (0.12 + pose.z * 0.3) - faixa * visor * 0.48);
	}

	float calor = halo(UV, vec2(0.15, 0.37), vec2(0.14, 0.23)) * luz.x;
	calor += halo(UV, vec2(0.86, 0.37), vec2(0.14, 0.23)) * luz.y;
	float cristal = halo(UV, vec2(0.50, 0.56), vec2(0.105, 0.21)) * luz.z;
	vec2 canto = (UV - 0.5) * vec2(1.0, 0.9);
	float moldura = smoothstep(0.18, 0.45, dot(canto, canto)) * 0.24;
	float rodape = smoothstep(0.71, 1.0, UV.y) * 0.32;
	arte.rgb *= 1.0 - moldura - rodape;
	arte.rgb *= 1.0 + calor * vec3(0.26, 0.13, 0.04) + cristal * vec3(0.08, 0.26, 0.37);
	arte.rgb += cascata * vec3(0.0, 0.012, 0.018);
	COLOR = arte;
}
