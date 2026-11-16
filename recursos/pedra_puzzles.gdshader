shader_type canvas_item;
// Unifica a pedra dos dois conjuntos existentes sem alterar as imagens originais.
void fragment() {
	vec4 pixel = COLOR;
	float cinza = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
	pixel.rgb = mix(pixel.rgb, vec3(cinza * 0.90, cinza * 0.98, cinza * 1.12), 0.85);
	COLOR = pixel;
}
