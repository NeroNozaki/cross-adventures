extends CanvasLayer
## Guia, diálogos e vínculo da dupla durante a partida.

signal fala_encerrada
const RETRATOS = preload("res://assets/INTERFACE/retratos_conversa.png")
const SOM_LETRA = preload("res://assets/SONS/INTERFACE/OUTROS/KENNEY_INTERFACE_SOUNDS/tick_001.ogg")
const SOM_BOTAO = preload("res://assets/SONS/INTERFACE/SELECAO/KENNEY_INTERFACE_SOUNDS/select_001.ogg")
const SOM_CONFIRMAR = preload("res://assets/SONS/INTERFACE/CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg")
const ARTE_BOTAO = preload("res://assets/INTERFACE/botao_reliquia.svg")
const ETAPAS = ["Conhecendo","Ajudando","Confiança","Parceria","Amigos"]

var conquistas: Dictionary = {}
var conversas: Dictionary = {}
var pontos := 0
var dialogando := false
var ajudando := false
var pagina_guia := 0
var grupos_guia: Array[Control] = []
var silenciado := false
var linhas: Array = []
var indice := 0
var letras := 0.0
var tempo := 0.0
var pausa_anterior := false
var foco_anterior: Control
var interface: Control
var ajuda: Control
var conversa: Control
var amizade: PanelContainer
var barra: ProgressBar
var estado: Label
var texto: Label
var nome: Label
var continuar: Button
var retratos: Array[TextureRect] = []
var voz: AudioStreamPlayer
var efeito: AudioStreamPlayer
var ponta_balao: Polygon2D
var coracoes_amizade: Array[TextureRect] = []

func moldura_pixel() -> StyleBoxTexture:
	var estilo := StyleBoxTexture.new()
	estilo.texture = load("res://assets/Ninja Adventure - Asset Pack/Ui/Theme/Wip/ThemeMetal3/nine_path_panel.png")
	for lado in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		estilo.set_texture_margin(lado,5)
		estilo.set_content_margin(lado,7)
	return estilo

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	interface = Control.new()
	interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(interface)
	voz = AudioStreamPlayer.new()
	voz.stream = SOM_LETRA
	voz.volume_db = -27
	add_child(voz)
	efeito = AudioStreamPlayer.new()
	efeito.volume_db = -15
	add_child(efeito)
	_criar_amizade()
	_criar_ajuda()
	_criar_conversa()
	get_tree().scene_changed.connect(_cena_mudou)
	_cena_mudou()

func _caixa(cor: Color = Color("#102632")) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = Color("#aa854c")
	estilo.set_border_width_all(2)
	estilo.set_content_margin_all(6)
	estilo.shadow_color = Color(0,0,0,0.38)
	estilo.shadow_size = 5
	return estilo

func _label(valor: String, tamanho: int = 14) -> Label:
	var item := Label.new()
	item.text = valor
	item.add_theme_font_size_override("font_size",tamanho)
	item.add_theme_color_override("font_color",Color("#f4eddb"))
	return item

func _botao(titulo: String) -> Button:
	var botao := Button.new()
	botao.text = titulo
	botao.custom_minimum_size.y = 28
	botao.add_theme_font_size_override("font_size",12)
	for estado_botao in ["normal","hover","focus","pressed"]:
		var placa := StyleBoxTexture.new()
		placa.texture = ARTE_BOTAO
		placa.texture_margin_left = 15
		placa.texture_margin_right = 15
		placa.texture_margin_top = 5
		placa.texture_margin_bottom = 5
		placa.content_margin_left = 18
		placa.content_margin_right = 18
		placa.modulate_color = Color(1.2,1.15,1.0) if estado_botao in ["hover","focus"] else Color.WHITE
		botao.add_theme_stylebox_override(estado_botao,placa)
	botao.mouse_entered.connect(_tocar.bind(SOM_BOTAO))
	botao.focus_entered.connect(_tocar.bind(SOM_BOTAO))
	botao.button_down.connect(_tocar.bind(SOM_CONFIRMAR))
	return botao

func _tocar(som: AudioStream) -> void:
	if silenciado:
		return
	efeito.stream = som
	efeito.play()

func _retrato(personagem: int, quadro: int = 0) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = RETRATOS
	var celula := RETRATOS.get_size() / Vector2(3,2)
	atlas.region = Rect2(Vector2(quadro,personagem)*celula,celula)
	return atlas

func _foto(personagem: int, tamanho: int) -> TextureRect:
	var foto := TextureRect.new()
	foto.texture = _retrato(personagem)
	foto.custom_minimum_size = Vector2(tamanho,tamanho)
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	foto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	foto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return foto

func _criar_amizade() -> void:
	amizade = PanelContainer.new()
	amizade.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	amizade.offset_left = -146
	amizade.offset_right = -10
	amizade.offset_top = 8
	amizade.offset_bottom = 49
	amizade.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	amizade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amizade.add_theme_stylebox_override("panel",moldura_pixel())
	interface.add_child(amizade)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation",2)
	amizade.add_child(coluna)
	var titulo := _label("LAÇO DA DUPLA",8)
	titulo.add_theme_color_override("font_color",Color("#8edce5"))
	coluna.add_child(titulo)
	estado = _label("Conhecendo",10)
	coluna.add_child(estado)
	var marcos := HBoxContainer.new()
	marcos.add_theme_constant_override("separation",5)
	coluna.add_child(marcos)
	for i in 4:
		var coracao := TextureRect.new()
		coracao.texture = load("res://assets/Ninja Adventure - Asset Pack/Ui/Receptacle/IconHeart.png")
		coracao.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coracao.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coracao.custom_minimum_size = Vector2(12,10)
		marcos.add_child(coracao)
		coracoes_amizade.append(coracao)
	barra = ProgressBar.new()
	barra.max_value = 4
	barra.show_percentage = false
	barra.custom_minimum_size.y = 4
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color("#071119")
	var preenchimento := StyleBoxFlat.new()
	preenchimento.bg_color = Color("#e4b964")
	barra.add_theme_stylebox_override("background",fundo)
	barra.add_theme_stylebox_override("fill",preenchimento)
	coluna.add_child(barra)
	barra.hide()

func _modal() -> Control:
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interface.add_child(raiz)
	var sombra := ColorRect.new()
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sombra.color = Color(0.015,0.035,0.06,0.82)
	raiz.add_child(sombra)
	raiz.hide()
	return raiz

func _tecla(acao: String) -> String:
	for evento in InputMap.action_get_events(acao):
		if evento is InputEventKey:
			var codigo: int = evento.physical_keycode if evento.physical_keycode else evento.keycode
			var nome_tecla := OS.get_keycode_string(codigo)
			if nome_tecla.begins_with("Kp "):
				return nome_tecla.trim_prefix("Kp ") + " numérico"
			return "Espaço" if nome_tecla == "Space" else nome_tecla
		if evento is InputEventMouseButton:
			return "Clique esq." if evento.button_index == MOUSE_BUTTON_LEFT else "Clique dir."
	return "—"

func _comando(coluna: VBoxContainer, modo: String, funcao: String, comando: String = "") -> void:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation",6)
	coluna.add_child(linha)
	var desenho := Control.new()
	desenho.set_script(load("res://scripts/screens/tecla_guia.gd"))
	desenho.configurar(modo,comando)
	linha.add_child(desenho)
	var legenda := _label(funcao,11)
	legenda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legenda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legenda.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(legenda)

func _trocar_pagina_guia(botao: Button) -> void:
	pagina_guia = 1-pagina_guia
	for grupo in grupos_guia:
		grupo.visible = int(grupo.get_meta("pagina")) == pagina_guia
	botao.text = "Controles principais" if pagina_guia == 1 else "Outras ações"

func _criar_ajuda() -> void:
	ajuda = _modal()
	var painel := PanelContainer.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	painel.offset_left = -270
	painel.offset_right = 270
	painel.offset_top = -165
	painel.offset_bottom = 165
	painel.add_theme_stylebox_override("panel",_caixa())
	ajuda.add_child(painel)
	var conteudo := VBoxContainer.new()
	conteudo.add_theme_constant_override("separation",6)
	painel.add_child(conteudo)
	var titulo := _label("Como jogar",18)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color",Color("#efcd83"))
	conteudo.add_child(titulo)
	var cartoes := HBoxContainer.new()
	cartoes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cartoes.add_theme_constant_override("separation",10)
	conteudo.add_child(cartoes)
	for personagem in 2:
		var moldura := PanelContainer.new()
		moldura.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var estilo := _caixa(Color("#172d34") if personagem == 0 else Color("#102b3a"))
		estilo.border_color = Color("#c7a160") if personagem == 0 else Color("#569eac")
		estilo.set_border_width_all(3)
		estilo.set_content_margin_all(6)
		moldura.add_theme_stylebox_override("panel",estilo)
		cartoes.add_child(moldura)
		var coluna := VBoxContainer.new()
		coluna.add_theme_constant_override("separation",4)
		moldura.add_child(coluna)
		var cabecalho := HBoxContainer.new()
		cabecalho.add_theme_constant_override("separation",8)
		coluna.add_child(cabecalho)
		cabecalho.add_child(_foto(personagem,40))
		var identidade := VBoxContainer.new()
		identidade.alignment = BoxContainer.ALIGNMENT_CENTER
		cabecalho.add_child(identidade)
		var nome_heroi := _label("LUCAS" if personagem == 0 else "OTTO",18)
		nome_heroi.add_theme_color_override("font_color",Color("#efcd83") if personagem == 0 else Color("#8de0e8"))
		identidade.add_child(nome_heroi)
		identidade.add_child(_label("Espada e escudo" if personagem == 0 else "Mira e esferas",10))
		var separador := HSeparator.new()
		coluna.add_child(separador)
		for pagina in 2:
			var comandos := VBoxContainer.new()
			# Espaçamento maior entre ações, principalmente entre disparo e carga.
			comandos.add_theme_constant_override("separation",6)
			comandos.set_meta("pagina",pagina)
			comandos.visible = pagina == 0
			grupos_guia.append(comandos)
			coluna.add_child(comandos)
			if pagina == 0:
				_comando(comandos,"lucas" if personagem == 0 else "otto","Andar")
				if personagem == 0:
					_comando(comandos,"tecla","Usar a espada","player1_atacar")
					_comando(comandos,"tecla","Segurar o escudo","player1_defender")
				else:
					_comando(comandos,"mouse_mira","Mover a mira")
					_comando(comandos,"mouse_esquerdo","Clique para disparar","player2_atacar")
					_comando(comandos,"segurar","Segure para carregar","player2_atacar")
			elif personagem == 0:
				_comando(comandos,"tecla","Pular","player1_pular")
				_comando(comandos,"tecla","Interagir","player1_interagir")
				var numerico := _label("0 e 5 ficam no teclado numérico.",11)
				numerico.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				comandos.add_child(numerico)
			else:
				_comando(comandos,"mouse_direito","Esquivar","player2_dash")
				_comando(comandos,"tecla","Pular","player2_pular")
				_comando(comandos,"tecla","Interagir","player2_interagir")
		var espaco := Control.new()
		espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
		coluna.add_child(espaco)
		var resumo := _label("Fique na placa para ajudar Otto." if personagem == 0 else "Acerte o alvo enquanto Lucas ajuda.",11)
		resumo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		coluna.add_child(resumo)
	conteudo.add_child(_label("Experimente as teclas ou clique nos desenhos.",11))
	var rodape := HBoxContainer.new()
	rodape.add_theme_constant_override("separation",8)
	conteudo.add_child(rodape)
	var mais := _botao("Outras ações")
	mais.name = "MaisAcoes"
	mais.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mais.pressed.connect(_trocar_pagina_guia.bind(mais))
	rodape.add_child(mais)
	var voltar := _botao("Voltar")
	voltar.name = "Voltar"
	voltar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	voltar.pressed.connect(fechar_ajuda)
	rodape.add_child(voltar)

func _criar_conversa() -> void:
	conversa = Control.new()
	conversa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interface.add_child(conversa)
	var escuro := ColorRect.new()
	escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	escuro.color = Color(0.015,0.035,0.06,0.10)
	conversa.add_child(escuro)
	var painel := PanelContainer.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	painel.offset_left = -180
	painel.offset_right = 180
	painel.offset_top = -104
	painel.offset_bottom = -14
	var balao := _caixa(Color(0.025,0.07,0.10,0.78))
	balao.set_corner_radius_all(12)
	balao.set_border_width_all(1)
	balao.border_color = Color(0.83,0.88,0.86,0.7)
	balao.set_content_margin_all(10)
	balao.shadow_size = 2
	painel.add_theme_stylebox_override("panel",balao)
	conversa.add_child(painel)
	ponta_balao = Polygon2D.new()
	conversa.add_child(ponta_balao)
	ponta_balao.color = balao.bg_color
	for i in 2:
		var foto := _foto(i,88)
		foto.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		foto.position = Vector2(-272 if i == 0 else 184,-108)
		foto.size = Vector2(88,88)
		conversa.add_child(foto)
		retratos.append(foto)
	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	painel.add_child(coluna)
	nome = _label("",12)
	nome.add_theme_color_override("font_color",Color("#efcd83"))
	coluna.add_child(nome)
	texto = _label("",12)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	coluna.add_child(texto)
	var acoes := HBoxContainer.new()
	acoes.alignment = BoxContainer.ALIGNMENT_END
	acoes.add_theme_constant_override("separation",8)
	coluna.add_child(acoes)
	var pular := _botao("Pular tudo")
	pular.name = "PularTudo"
	pular.pressed.connect(_encerrar_conversa)
	acoes.add_child(pular)
	continuar = _botao("Continuar")
	continuar.pressed.connect(avancar)
	acoes.add_child(continuar)
	conversa.hide()

func abrir_ajuda() -> void:
	if dialogando or ajudando:
		return
	ajudando = true
	if pagina_guia != 0:
		_trocar_pagina_guia(ajuda.find_child("MaisAcoes",true,false))
	pausa_anterior = get_tree().paused
	foco_anterior = get_viewport().gui_get_focus_owner()
	get_tree().paused = true
	ajuda.show()
	var botao = ajuda.find_child("Voltar",true,false)
	botao.grab_focus()
	amizade.hide()

func fechar_ajuda() -> void:
	ajuda.hide()
	ajudando = false
	get_tree().paused = pausa_anterior
	if is_instance_valid(foco_anterior) and foco_anterior.is_visible_in_tree():
		foco_anterior.grab_focus()
	_cena_mudou()

func nova_partida() -> void:
	conquistas.clear()
	conversas.clear()
	pontos = 0
	barra.value = 0
	_atualizar_amizade()

func ganhar(id: String) -> void:
	if conquistas.has(id):
		return
	conquistas[id] = true
	pontos = mini(4,pontos+1)
	create_tween().tween_property(barra,"value",pontos,0.7)
	_atualizar_amizade()

func _atualizar_amizade() -> void:
	estado.text = ETAPAS[pontos]
	for i in coracoes_amizade.size():
		coracoes_amizade[i].modulate = Color.WHITE if i < pontos else Color(0.32,0.39,0.43,0.8)

func falar(id: String, falas: Array) -> void:
	var cena := get_tree().current_scene
	if cena == null or cena.scene_file_path != "res://cenas/areas/bosque.tscn":
		return
	while FluxoTela.em_transicao:
		await get_tree().process_frame
	if conversas.has(id) or falas.is_empty() or dialogando or ajudando:
		return
	conversas[id] = true
	linhas = falas
	indice = 0
	dialogando = true
	pausa_anterior = get_tree().paused
	foco_anterior = get_viewport().gui_get_focus_owner()
	get_tree().paused = true
	conversa.show()
	_mostrar_linha()
	await fala_encerrada

func _mostrar_linha() -> void:
	letras = 0
	var personagem: int = linhas[indice][0]
	var centro := conversa.size * Vector2(0.5,1.0)
	var lado := -1.0 if personagem == 0 else 1.0
	ponta_balao.position = centro
	ponta_balao.polygon = PackedVector2Array([
		Vector2(lado*179,-80),Vector2(lado*194,-65),Vector2(lado*179,-68)
	])
	nome.text = "Lucas" if personagem == 0 else "Otto"
	texto.text = linhas[indice][1]
	texto.visible_characters = 0
	continuar.text = "Continuar"
	for i in 2:
		retratos[i].modulate = Color.WHITE if i == personagem else Color(0.48,0.55,0.62)
		retratos[i].texture = _retrato(i)
	continuar.grab_focus()
	_visibilidade_dica(false)

func _visibilidade_dica(ativa: bool) -> void:
	var cena := get_tree().current_scene
	if cena:
		var dica := cena.get_node_or_null("Dicas/Texto")
		if dica:
			dica.visible = ativa

func avancar() -> void:
	if not dialogando:
		return
	if letras < texto.text.length():
		letras = texto.text.length()
		texto.visible_characters = -1
		continuar.text = "Continuar"
		retratos[int(linhas[indice][0])].texture = _retrato(int(linhas[indice][0]))
		return
	indice += 1
	if indice < linhas.size():
		_mostrar_linha()
	else:
		_encerrar_conversa()

func _encerrar_conversa() -> void:
	if not dialogando:
		return
	dialogando = false
	conversa.hide()
	_visibilidade_dica(true)
	voz.stop()
	get_tree().paused = pausa_anterior
	if is_instance_valid(foco_anterior) and foco_anterior.is_visible_in_tree():
		foco_anterior.grab_focus()
	fala_encerrada.emit()

func _process(delta: float) -> void:
	if not dialogando:
		return
	tempo += delta
	var personagem: int = linhas[indice][0]
	for i in 2:
		retratos[i].pivot_offset = retratos[i].size * 0.5
		var destaque := 1.0 + sin(tempo*2.4)*0.015 if i == personagem else 1.0
		retratos[i].scale = Vector2.ONE * destaque
	if letras < texto.text.length():
		var antes := int(letras)
		letras = minf(texto.text.length(),letras+delta*27)
		texto.visible_characters = int(letras)
		if int(letras)/3 > antes/3:
			voz.pitch_scale = 1.12 if personagem == 0 else 0.77
			if not silenciado:
				voz.play()
		var quadro: int = [0,1,2,1][int(tempo*9)%4]
		retratos[personagem].texture = _retrato(personagem,quadro)
	else:
		continuar.text = "Continuar" if indice < linhas.size()-1 else "Finalizar"
		retratos[personagem].texture = _retrato(personagem)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("alternar_audio"):
		silenciado = not silenciado
		voz.stream_paused = silenciado
		efeito.stream_paused = silenciado
		if dialogando or ajudando:
			var cena := get_tree().current_scene
			if cena:
				for player in cena.find_children("*","AudioStreamPlayer",true,false):
					player.stream_paused = silenciado
			get_viewport().set_input_as_handled()
		return
	if ajudando and event.is_action_pressed("ui_cancel"):
		fechar_ajuda()
		get_viewport().set_input_as_handled()
	elif ajudando and event is InputEventKey and event.physical_keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
	elif dialogando and event.is_action_pressed("ui_accept"):
		avancar()
		get_viewport().set_input_as_handled()
	elif dialogando and event.is_action_pressed("ui_cancel"):
		# Uma fala pode ser completada de imediato; cada criança decide quando avançar.
		avancar()
		get_viewport().set_input_as_handled()

func _cena_mudou() -> void:
	var atual := get_tree().current_scene
	var em_fase := atual != null and atual.scene_file_path.begins_with("res://cenas/areas/")
	amizade.visible = em_fase and not ajudando
	if atual:
		var dica := atual.get_node_or_null("Dicas/Texto")
		if dica:
			dica.offset_top = 48
	_atualizar_amizade()
