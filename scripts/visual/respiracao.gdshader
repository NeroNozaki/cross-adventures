shader_type canvas_item;
uniform float inspiracao : hint_range(0.0, 1.0) = 0.0;
varying vec4 tinta;
void vertex() { tinta = COLOR; }
void fragment() {
	// Um pixel no torso/cabeça; a faixa inferior e os pés mantêm a posição original.
	vec2 uv = UV;
	float faixa = 1.0 - step(0.68, UV.y);
	uv.y += step(0.5,inspiracao) * TEXTURE_PIXEL_SIZE.y * faixa;
	COLOR = texture(TEXTURE, uv) * tinta;
}
