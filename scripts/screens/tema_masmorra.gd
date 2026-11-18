extends RefCounted
## A pedra, o bronze e o ciano unem as telas da campanha.
const MOLDURA = preload("res://assets/INTERFACE/moldura_masmorra.svg")
const BOTAO = preload("res://assets/INTERFACE/botao_masmorra.svg")
const CAMINHO_FONTE := "res://assets/INTERFACE/FONTES/CrossInscricao.ttf"
const OURO := Color("f4d494")
const CIANO := Color("9de1e3")
const PAPEL := Color("f2f0e7")
const SUAVE := Color("bbcad3")

static func painel(recuo: float = 8.0) -> StyleBoxTexture:
	var estilo := StyleBoxTexture.new()
	estilo.texture = MOLDURA
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		estilo.set_texture_margin(lado, 8)
		estilo.set_content_margin(lado, recuo)
	return estilo

static var _inscricao: Font

static func letra(controle: Control, tamanho: int) -> void:
	if _inscricao == null:
		_inscricao = load(CAMINHO_FONTE)
	controle.add_theme_font_override("font", _inscricao)
	controle.add_theme_font_size_override("font_size", tamanho)

static func botao(controle: Button, destaque: bool = false, fonte: int = 13, altura: float = 28) -> void:
	controle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	controle.custom_minimum_size.y = altura
	letra(controle, fonte)
	controle.add_theme_color_override("font_color", PAPEL if destaque else SUAVE)
	controle.add_theme_color_override("font_hover_color", Color.WHITE)
	controle.add_theme_color_override("font_focus_color", Color.WHITE)
	controle.add_theme_color_override("font_pressed_color", OURO)
	controle.add_theme_color_override("font_disabled_color", Color("82909a"))
	var cores := {
		"normal": Color.WHITE if destaque else Color(0.78, 0.85, 0.92),
		"hover": Color(1.19, 1.22, 1.24),
		"pressed": Color(0.76, 0.86, 0.87),
		"disabled": Color(0.49, 0.52, 0.59)
	}
	for estado in cores:
		var estilo := StyleBoxTexture.new()
		estilo.texture = BOTAO
		estilo.texture_margin_left = 15
		estilo.texture_margin_right = 15
		estilo.texture_margin_top = 8
		estilo.texture_margin_bottom = 8
		estilo.content_margin_left = 16
		estilo.content_margin_right = 16
		estilo.content_margin_top = 2
		estilo.content_margin_bottom = 4
		estilo.modulate_color = cores[estado]
		if estado == "pressed":
			estilo.content_margin_top = 4
			estilo.content_margin_bottom = 2
		controle.add_theme_stylebox_override(estado, estilo)
	var foco := StyleBoxFlat.new()
	foco.draw_center = false
	foco.border_color = Color("f6d9a5")
	foco.set_border_width_all(1)
	foco.set_corner_radius_all(3)
	foco.set_expand_margin_all(1)
	controle.add_theme_stylebox_override("focus", foco)
