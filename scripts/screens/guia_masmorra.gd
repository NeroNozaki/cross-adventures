extends PanelContainer
## Guia curto com retratos da capa e um comando por linha.
signal fechar

const TEMA = preload("res://scripts/screens/tema_masmorra.gd")
const CAPA = preload("res://assets/INTERFACE/capa_nico_otto.png")
const INPUTS := "res://assets/Ninja Adventure - Asset Pack/Ui/Input/"
const WASD := [preload(INPUTS + "Keyboard/KeyW.png"), preload(INPUTS + "Keyboard/KeyA.png"),
	preload(INPUTS + "Keyboard/KeyS.png"), preload(INPUTS + "Keyboard/KeyD.png")]
const SETAS := [preload(INPUTS + "Keyboard/KeyUp.png"), preload(INPUTS + "Keyboard/KeyLeft.png"),
	preload(INPUTS + "Keyboard/KeyDown.png"), preload(INPUTS + "Keyboard/KeyRight.png")]
const ANALOGICO = preload(INPUTS + "Gamepad/JoystickLeft.png")
const TECLA_F = preload(INPUTS + "Keyboard/KeyF.png")
const TECLA_G = preload(INPUTS + "Keyboard/KeyG.png")
const BOTAO_X = preload(INPUTS + "Gamepad/ButtonX/Idle.png")
const BOTAO_B = preload(INPUTS + "Gamepad/ButtonB/Idle.png")
const MOUSE = preload(INPUTS + "Mouse/MouseButtonLeft.png")
var voltar: Button

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_stylebox_override("panel", TEMA.painel(14))
	custom_minimum_size = Vector2(530, 0)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 11)
	add_child(coluna)
	var titulo := _rotulo("Como jogar", 22, TEMA.OURO)
	TEMA.letra(titulo, 22)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(titulo)
	var cartoes := HBoxContainer.new()
	cartoes.add_theme_constant_override("separation", 10)
	coluna.add_child(cartoes)
	var nico := _cartao(cartoes, "Nico", "Golpe e escudo", TEMA.OURO, Rect2(141, 449, 352, 257))
	_comando(nico, "Andar no teclado", WASD)
	_comando(nico, "Andar no controle", [ANALOGICO, "Analógico esquerdo"])
	_comando(nico, "Dar um golpe", [TECLA_F, "ou", BOTAO_X])
	_comando(nico, "Usar o escudo", [TECLA_G, "ou", BOTAO_B])
	var dica := _rotulo("Fique na placa para ajudar Otto.", 11, TEMA.OURO)
	dica.custom_minimum_size.y = 23.0
	dica.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nico.add_child(dica)
	var otto := _cartao(cartoes, "Otto", "Mira e esferas", TEMA.CIANO, Rect2(1222, 450, 354, 259))
	_comando(otto, "Andar", SETAS)
	_comando(otto, "Mirar", ["Mover o mouse"])
	_comando(otto, "Disparar", [MOUSE, "Clique esquerdo"])
	_comando(otto, "Carregar", [MOUSE, "Segure o esquerdo"])
	_comando(otto, "Dar um impulso", [MOUSE, "Clique direito"], true)

	voltar = Button.new()
	voltar.text = "Entendi!"
	voltar.custom_minimum_size.x = 136
	voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	TEMA.botao(voltar, true, 13, 28)
	voltar.pressed.connect(fechar.emit)
	# O guia é modal, inclusive para a navegação por teclado.
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		voltar.set_focus_neighbor(lado, NodePath("."))
	voltar.focus_next = NodePath(".")
	voltar.focus_previous = NodePath(".")
	coluna.add_child(voltar)

func _cartao(pai: HBoxContainer, nome: String, habilidade: String, cor: Color, regiao: Rect2) -> VBoxContainer:
	var cartao := PanelContainer.new()
	cartao.custom_minimum_size.x = 258
	cartao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("182732") if nome == "Nico" else Color("132937")
	estilo.border_color = cor.darkened(0.48)
	estilo.set_border_width_all(1)
	estilo.border_width_top = 2
	estilo.set_content_margin_all(8)
	cartao.add_theme_stylebox_override("panel", estilo)
	pai.add_child(cartao)
	var conteudo := VBoxContainer.new()
	conteudo.add_theme_constant_override("separation", 5)
	cartao.add_child(conteudo)
	var cabecalho := HBoxContainer.new()
	cabecalho.add_theme_constant_override("separation", 10)
	conteudo.add_child(cabecalho)

	var atlas := AtlasTexture.new()
	atlas.atlas = CAPA
	atlas.region = regiao
	atlas.filter_clip = true
	var retrato := _icone(atlas, Vector2(80, 58))
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	cabecalho.add_child(retrato)

	var identidade := VBoxContainer.new()
	identidade.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	identidade.add_theme_constant_override("separation", 0)
	cabecalho.add_child(identidade)
	var personagem := _rotulo(nome, 22, cor)
	TEMA.letra(personagem, 22)
	identidade.add_child(personagem)
	identidade.add_child(_rotulo(habilidade, 11, TEMA.SUAVE))

	var divisor := ColorRect.new()
	divisor.color = cor.darkened(0.69)
	divisor.custom_minimum_size.y = 1
	conteudo.add_child(divisor)
	return conteudo

func _comando(pai: VBoxContainer, acao: String, entradas: Array, botao_direito := false) -> void:
	var faixa := PanelContainer.new()
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("10202c")
	if pai.get_child_count() % 2 != 0:
		fundo.bg_color = Color("1d3543")
	fundo.content_margin_left = 6
	fundo.content_margin_right = 6
	faixa.add_theme_stylebox_override("panel", fundo)
	pai.add_child(faixa)
	var linha := HBoxContainer.new()
	linha.custom_minimum_size.y = 23
	linha.add_theme_constant_override("separation", 5)
	faixa.add_child(linha)
	var nome := _rotulo(acao, 12, TEMA.PAPEL)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(nome)
	for entrada in entradas:
		if entrada is Texture2D:
			var icone := _icone(entrada, Vector2(17, 18))
			icone.flip_h = botao_direito
			linha.add_child(icone)
		else:
			linha.add_child(_rotulo(entrada, 10, TEMA.SUAVE))

func _icone(textura: Texture2D, dimensoes: Vector2) -> TextureRect:
	var imagem := TextureRect.new()
	imagem.texture = textura
	imagem.custom_minimum_size = dimensoes
	imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return imagem

func _rotulo(texto: String, fonte: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_font_size_override("font_size", fonte)
	return rotulo
