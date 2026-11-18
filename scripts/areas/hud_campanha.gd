extends CanvasLayer
## Informações de partida compactas e dicas que saem do caminho.
const CAPITULOS := [
	["Celas e cristais", "Pisem nas placas e testem o que cada cristal abre."],
	["Galeria das plataformas", "Um amigo aciona o mecanismo. O outro atravessa."],
	["Caminho da saída", "Usem o escudo nos corredores. Ativem as placas juntos."]
]
var aviso: Label
var tempo := 0.0
var pendente := ""

func _ready() -> void:
	layer = 20
	var fase: int = get_parent().fase_historia
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)

	var faixa := _moldura(raiz, Color("af8854"))
	faixa.position = Vector2(9, 9)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 9)
	faixa.add_child(linha)
	linha.add_child(_texto("%d/3" % fase, Color("ffdc91"), 11))
	linha.add_child(_texto(CAPITULOS[fase - 1][0], Color("f4eeff"), 11))
	for heroi in get_tree().get_nodes_in_group("herois"):
		if get_parent().is_ancestor_of(heroi):
			var cor := Color("f6d485") if heroi.nome_personagem == "Nico" else Color("abe9f3")
			var vida := _texto("", cor, 10)
			linha.add_child(vida)
			_atualizar_vida(heroi.vida_atual, heroi.vida_maxima, vida, heroi.nome_personagem)
			heroi.vida_alterada.connect(_atualizar_vida.bind(vida, heroi.nome_personagem))

	var ajuda := _moldura(raiz, Color("578397"))
	ajuda.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ajuda.offset_left = -70
	ajuda.offset_right = -9
	ajuda.offset_top = -32
	ajuda.offset_bottom = -9
	var botao := Button.new()
	botao.name = "AbrirGuia"
	botao.text = "F1  Guia"
	botao.focus_mode = Control.FOCUS_NONE
	botao.flat = true
	botao.add_theme_font_size_override("font_size", 10)
	botao.pressed.connect(get_parent().abrir_guia)
	ajuda.add_child(botao)

	var dica := _moldura(raiz, Color("578397"))
	dica.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	dica.offset_top = 44
	dica.offset_left = -163
	dica.offset_right = 163
	aviso = _texto("", Color("f4eeff"), 11)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.add_child(aviso)
	dica.hide()
	pendente = CAPITULOS[fase - 1][1]
	var abrigo := get_parent().get_node_or_null("Checkpoint") as Checkpoint
	if abrigo:
		abrigo.reached.connect(func(): pendente = "Abrigo ativado. Se caírem, os dois voltam para cá.")

func _moldura(raiz: Control, borda: Color) -> PanelContainer:
	var painel := PanelContainer.new()
	painel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.045, 0.08, 0.13, 0.91)
	estilo.border_color = borda
	estilo.set_border_width_all(1)
	estilo.border_width_bottom = 2
	estilo.set_content_margin_all(5)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	painel.add_theme_stylebox_override("panel", estilo)
	raiz.add_child(painel)
	return painel

func _texto(titulo: String, cor: Color, tamanho: int) -> Label:
	var rotulo := Label.new()
	rotulo.text = titulo
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_font_size_override("font_size", tamanho)
	return rotulo

func _atualizar_vida(atual: int, total: int, rotulo: Label, personagem: String) -> void:
	rotulo.text = "%s %d/%d" % [personagem, atual, total]

func _process(delta: float) -> void:
	if FluxoTela.em_transicao or HistoriaDupla.ativa:
		return
	var painel := aviso.get_parent() as Control
	if not pendente.is_empty():
		aviso.text = pendente
		pendente = ""
		tempo = 4.0
		painel.show()
	tempo = maxf(0.0, tempo - delta)
	painel.modulate.a = clampf(tempo / 0.42, 0.0, 1.0)
	painel.visible = tempo > 0.0
