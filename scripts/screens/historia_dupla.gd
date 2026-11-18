extends CanvasLayer
signal encerrada
const DADOS = preload("res://recursos/historia_dupla.gd")
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
var voz: AudioStreamPlayer

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
	painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	painel.offset_left = -225
	painel.offset_right = 225
	painel.offset_top = -114
	painel.offset_bottom = -12
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.025,0.07,0.10,0.82)
	estilo.border_color = Color(0.6,0.8,0.82,0.8)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(12)
	estilo.set_content_margin_all(10)
	painel.add_theme_stylebox_override("panel",estilo)
	raiz.add_child(painel)
	var ponta := Polygon2D.new()
	ponta.polygon = PackedVector2Array([Vector2(140,0),Vector2(152,-10),Vector2(164,0)])
	ponta.color = estilo.bg_color
	painel.add_child(ponta)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation",10)
	painel.add_child(linha)
	retrato = TextureRect.new()
	retrato.custom_minimum_size = Vector2(64,64)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	linha.add_child(retrato)
	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(coluna)
	nome = Label.new()
	nome.add_theme_font_size_override("font_size",12)
	nome.add_theme_color_override("font_color",Color("#efcc82"))
	coluna.add_child(nome)
	texto = Label.new()
	texto.add_theme_font_size_override("font_size",12)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	coluna.add_child(texto)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_END
	coluna.add_child(botoes)
	var pular := Button.new()
	pular.text = "Pular tudo"
	pular.pressed.connect(finalizar)
	botoes.add_child(pular)
	continuar = Button.new()
	continuar.text = "Continuar"
	continuar.pressed.connect(avancar)
	botoes.add_child(continuar)
	for b in [pular,continuar]:
		b.custom_minimum_size = Vector2(96,26)
		b.add_theme_font_size_override("font_size",12)
		for estado in ["normal","hover","pressed","focus"]:
			var placa := StyleBoxTexture.new()
			placa.texture = load("res://assets/INTERFACE/botao_reliquia.svg")
			placa.texture_margin_left = 15
			placa.texture_margin_right = 15
			placa.modulate_color = Color(1.2,1.15,1) if estado in ["hover","focus"] else Color.WHITE
			b.add_theme_stylebox_override(estado,placa)
	vinculo = Label.new()
	vinculo.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	vinculo.offset_left = -150
	vinculo.offset_top = 8
	vinculo.add_theme_font_size_override("font_size",10)
	vinculo.add_theme_color_override("font_shadow_color",Color.BLACK)
	vinculo.add_theme_constant_override("shadow_offset_x",1)
	vinculo.add_theme_constant_override("shadow_offset_y",1)
	raiz.add_child(vinculo)
	vinculo.hide()
	voz = AudioStreamPlayer.new()
	voz.stream = load("res://assets/SONS/INTERFACE/OUTROS/KENNEY_INTERFACE_SOUNDS/tick_001.ogg")
	voz.volume_db = -30
	add_child(voz)
	painel.hide()
	get_tree().scene_changed.connect(func():
		var cena := get_tree().current_scene
		vinculo.visible = cena != null and cena is BaseArea)

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
	painel.show()
	_mostrar()
	await encerrada

func _mostrar() -> void:
	nome.text = falas[indice][0]
	texto.text = falas[indice][1]
	texto.visible_characters = 0
	letras = 0
	if nome.text == "Nico":
		retrato.texture = load("res://assets/Ninja Adventure - Asset Pack/Actor/Character/Skeleton/Faceset.png")
	else:
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/INTERFACE/retratos_otto.png")
		atlas.region = Rect2(0,512,512,512)
		retrato.texture = atlas
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
	if int(letras)/3 > antes/3:
		voz.pitch_scale = 1.15 if nome.text == "Nico" else 0.8
		if not silenciado:
			voz.play()
	retrato.pivot_offset = retrato.size/2
	retrato.scale = Vector2.ONE*(1+sin(tempo*3)*0.012)
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
		avancar()
		get_viewport().set_input_as_handled()
