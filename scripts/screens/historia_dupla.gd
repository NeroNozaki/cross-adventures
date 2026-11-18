extends CanvasLayer
signal encerrada
const DADOS = preload("res://recursos/historia_dupla.gd")
const TEMA = preload("res://scripts/screens/tema_masmorra.gd")
const FACE_NICO = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Character/Skeleton/Faceset.png")
const FACES_OTTO = preload("res://assets/INTERFACE/retratos_otto.png")
const SOM_BOTAO = preload("res://assets/SONS/INTERFACE/CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg")
var fase := 1
var pontos := 0
var vistos: Dictionary = {}
var ativa := false
var silenciado := false
var pausa_anterior := false
var foco_anterior: Control
var falas: Array = []
var indice := 0
var letras := 0.0
var tempo := 0.0
var raiz: Control
var painel: PanelContainer
var nome: Label
var texto: Label
var continuar: Button
var retrato: TextureRect
var vinculo: Label
var ficha_vinculo: PanelContainer
var selos: Array[ColorRect] = []
var pagina: Label
var pulso: Control
var cor_fala := TEMA.CIANO
var entrada_fala: Tween
var voz: AudioStreamPlayer
var som_botao: AudioStreamPlayer

func nova_partida() -> void:
	vistos.clear()
	pontos = 0
	fase = 1

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	raiz = Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	painel = PanelContainer.new()
	painel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	painel.add_theme_stylebox_override("panel", TEMA.painel(9))
	raiz.add_child(painel)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation",10)
	painel.add_child(linha)
	var selo := PanelContainer.new()
	selo.add_theme_stylebox_override("panel", TEMA.painel(3))
	selo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(selo)
	retrato = TextureRect.new()
	retrato.custom_minimum_size = Vector2(46, 50)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	selo.add_child(retrato)
	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(coluna)
	var cabecalho := HBoxContainer.new()
	cabecalho.add_theme_constant_override("separation", 7)
	coluna.add_child(cabecalho)
	nome = Label.new()
	TEMA.letra(nome, 12)
	cabecalho.add_child(nome)
	pulso = Control.new()
	pulso.custom_minimum_size = Vector2(15, 12)
	pulso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulso.draw.connect(_desenhar_voz)
	cabecalho.add_child(pulso)
	pagina = Label.new()
	pagina.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pagina.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pagina.add_theme_font_size_override("font_size", 9)
	pagina.add_theme_color_override("font_color", TEMA.SUAVE)
	cabecalho.add_child(pagina)
	texto = Label.new()
	texto.add_theme_font_size_override("font_size",12)
	texto.add_theme_color_override("font_color", TEMA.PAPEL)
	texto.custom_minimum_size.y = 32
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	coluna.add_child(texto)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_END
	botoes.add_theme_constant_override("separation", 7)
	coluna.add_child(botoes)
	var pular := Button.new()
	pular.text = "Pular tudo"
	pular.pressed.connect(finalizar)
	botoes.add_child(pular)
	continuar = Button.new()
	continuar.text = "Continuar"
	continuar.pressed.connect(avancar)
	botoes.add_child(continuar)
	for b in [pular, continuar]:
		b.custom_minimum_size.x = 88
		TEMA.botao(b, b == continuar, 11, 24)
		b.button_down.connect(_tocar_botao)
	ficha_vinculo = PanelContainer.new()
	ficha_vinculo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ficha_vinculo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ficha_vinculo.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	ficha_vinculo.offset_left = -149
	ficha_vinculo.offset_right = -9
	ficha_vinculo.offset_top = 9
	ficha_vinculo.add_theme_stylebox_override("panel", TEMA.painel(6))
	raiz.add_child(ficha_vinculo)
	var coluna_vinculo := VBoxContainer.new()
	coluna_vinculo.add_theme_constant_override("separation", 2)
	ficha_vinculo.add_child(coluna_vinculo)
	vinculo = Label.new()
	vinculo.add_theme_font_size_override("font_size", 9)
	vinculo.add_theme_color_override("font_color", TEMA.PAPEL)
	coluna_vinculo.add_child(vinculo)
	var trilha := HBoxContainer.new()
	trilha.add_theme_constant_override("separation", 3)
	coluna_vinculo.add_child(trilha)
	for i in 3:
		var marca := ColorRect.new()
		marca.custom_minimum_size.y = 3
		marca.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		trilha.add_child(marca)
		selos.append(marca)
	ficha_vinculo.hide()
	voz = AudioStreamPlayer.new()
	voz.stream = load("res://assets/SONS/INTERFACE/OUTROS/KENNEY_INTERFACE_SOUNDS/tick_001.ogg")
	voz.volume_db = -30
	add_child(voz)
	som_botao = AudioStreamPlayer.new()
	som_botao.volume_db = -24
	som_botao.stream = SOM_BOTAO
	add_child(som_botao)
	painel.hide()
	get_tree().scene_changed.connect(func():
		var cena := get_tree().current_scene
		ficha_vinculo.visible = cena != null and cena is BaseArea)

func iniciar_fase(numero: int) -> void:
	fase = clampi(numero,1,3)
	_atualizar_vinculo()
	await falar("inicio_%d"%fase,DADOS.FASES[str(fase)].inicio)

func concluir_fase(numero: int) -> void:
	var chave := "fim_%d"%numero
	if vistos.has(chave):
		return
	pontos = maxi(pontos,numero)
	_atualizar_vinculo()
	await falar(chave,DADOS.FASES[str(clampi(numero,1,3))].fim)

func _atualizar_vinculo() -> void:
	vinculo.text = "Amizade %d/3 · %s" % [pontos, ["Conhecendo","Uma ajuda","Confiança","Amigos"][clampi(pontos,0,3)]]
	for i in selos.size():
		selos[i].color = TEMA.OURO if i < pontos else Color("3c5262")

func falar(id: String, linhas: Array) -> void:
	while FluxoTela.em_transicao:
		await get_tree().process_frame
	if ativa or vistos.has(id) or linhas.is_empty():
		return
	vistos[id] = true
	falas = linhas
	indice = 0
	pausa_anterior = get_tree().paused
	foco_anterior = get_viewport().gui_get_focus_owner()
	ativa = true
	get_tree().paused = true
	_posicionar_painel()
	painel.modulate.a = 0.0
	painel.show()
	entrada_fala = create_tween()
	entrada_fala.tween_property(painel, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	_mostrar()
	await encerrada

func _mostrar() -> void:
	nome.text = falas[indice][0]
	texto.text = falas[indice][1]
	pagina.text = "%d / %d" % [indice + 1, falas.size()]
	texto.visible_characters = 0
	letras = 0
	if nome.text == "Nico":
		retrato.texture = FACE_NICO
		cor_fala = TEMA.OURO
	else:
		var atlas := AtlasTexture.new()
		atlas.atlas = FACES_OTTO
		atlas.region = Rect2(0,512,512,512)
		retrato.texture = atlas
		cor_fala = TEMA.CIANO
	nome.add_theme_color_override("font_color", cor_fala)
	continuar.text = "Continuar"
	continuar.grab_focus()

func avancar() -> void:
	if not ativa:
		return
	if letras < texto.text.length():
		letras = texto.text.length()
		texto.visible_characters = -1
		return
	indice += 1
	if indice >= falas.size():
		finalizar()
	else:
		_mostrar()

func finalizar() -> void:
	if not ativa:
		return
	ativa = false
	if entrada_fala and entrada_fala.is_valid():
		entrada_fala.kill()
	painel.hide()
	voz.stop()
	get_tree().paused = pausa_anterior
	if is_instance_valid(foco_anterior) and foco_anterior.is_visible_in_tree():
		foco_anterior.grab_focus()
	encerrada.emit()

func _process(delta: float) -> void:
	if not ativa:
		return
	voz.stream_paused = silenciado
	tempo += delta
	var antes := int(letras)
	letras = minf(texto.text.length(),letras+delta*28)
	texto.visible_characters = int(letras)
	if floori(letras / 3.0) > floori(antes / 3.0):
		voz.pitch_scale = 1.15 if nome.text == "Nico" else 0.8
		if not silenciado:
			voz.play()
	retrato.pivot_offset = retrato.size/2
	var escrevendo := letras < texto.text.length()
	retrato.scale = Vector2.ONE * (1.0 + (sin(tempo * 6.0) * 0.016 if escrevendo else 0.0))
	pulso.queue_redraw()
	continuar.text = "Finalizar" if indice == falas.size()-1 and letras >= texto.text.length() else "Continuar"

func _input(event: InputEvent) -> void:
	if not ativa or (event is InputEventKey and event.echo):
		return
	if event.is_action_pressed("alternar_audio"):
		silenciado = not silenciado
		voz.stream_paused = silenciado
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		if get_viewport().gui_get_focus_owner() != continuar:
			return
		_tocar_botao()
		avancar()
		get_viewport().set_input_as_handled()

func _tocar_botao() -> void:
	if not silenciado:
		som_botao.play()

func _posicionar_painel() -> void:
	var altura := get_viewport().get_visible_rect().size.y
	var acima := false
	for heroi in get_tree().get_nodes_in_group("herois"):
		if heroi.get_global_transform_with_canvas().origin.y > altura * 0.72:
			acima = true
			break
	painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP if acima else Control.PRESET_CENTER_BOTTOM)
	painel.offset_left = -186
	painel.offset_right = 186
	painel.offset_top = 44 if acima else -106
	painel.offset_bottom = 140 if acima else -10

func _desenhar_voz() -> void:
	var cor := cor_fala
	cor.a = 0.68
	var escrevendo := letras < texto.text.length()
	for i in 3:
		var h := roundf(2.0 + absf(sin(tempo * 12.0 + i * 1.1)) * 4.0) if escrevendo else 2.0
		pulso.draw_rect(Rect2(1 + i * 4, floorf((pulso.size.y - h) * 0.5), 2, h), cor)
