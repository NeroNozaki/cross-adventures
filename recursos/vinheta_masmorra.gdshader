shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec2 ponto = (UV - 0.5) * vec2(1.0, 0.86);
	float borda = smoothstep(0.32, 0.69, length(ponto));
	COLOR = vec4(0.015, 0.025, 0.045, borda * 0.18);
}
