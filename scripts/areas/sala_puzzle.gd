extends BaseArea
const MAPAS = preload("res://recursos/mapas_puzzle.gd")
@export var mapa_id := 1
var dados: Dictionary
var pronta := false
var resolvida := false
var animando := false
var progresso := 0
var placa_ativa := false
var ajuda_otto := false
var roda_ativa := false
var pistas_lidas: Dictionary = {}
var erros_sequencia := 0
var tempo_aviso := 0.0
var ocioso := 0.0
var dica_dada := false
var achados: Dictionary = {}
var aviso: Label
var objetivo: Label
var musica: AudioStreamPlayer
var som: AudioStreamPlayer
@onready var nico: Heroi = $Personagens/Nico
@onready var otto: Heroi = $Personagens/Otto

func _ready() -> void:
	dados = MAPAS.FASES[mapa_id]
	fase_historia = mapa_id
	super._ready()
	if has_node("PlacaNico"):
		$PlacaNico/hitbox.collision_mask = 0
	if has_node("PlacaOtto"):
		$PlacaOtto/hitbox.collision_mask = 0
	$Saida.monitoring = false
	for heroi in [nico,otto]:
		heroi.get_node("BarraVida").hide()
		heroi.nome_label.text = "Nico" if heroi == nico else "Otto"
		var passos := Node.new()
		passos.set_script(load("res://scripts/areas/passos_puzzle.gd"))
		heroi.add_child(passos)
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	var painel := PanelContainer.new()
	painel.position = Vector2(8,8)
	var estilo := StyleBoxTexture.new()
	estilo.texture = load("res://assets/Ninja Adventure - Asset Pack/Ui/Theme/Wip/ThemeMetal3/nine_path_panel.png")
	for lado in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		estilo.set_texture_margin(lado,5)
		estilo.set_content_margin(lado,6)
	painel.add_theme_stylebox_override("panel",estilo)
	painel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.add_child(painel)
	objetivo = Label.new()
	objetivo.add_theme_font_size_override("font_size",10)
	painel.add_child(objetivo)
	aviso = Label.new()
	aviso.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	aviso.offset_left = -250
	aviso.offset_right = 250
	aviso.offset_top = 51
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.add_theme_font_size_override("font_size",11)
	aviso.add_theme_color_override("font_shadow_color",Color.BLACK)
	aviso.add_theme_constant_override("shadow_offset_x",1)
	aviso.add_theme_constant_override("shadow_offset_y",1)
	canvas.add_child(aviso)
	som = AudioStreamPlayer.new()
	som.volume_db = -18
	add_child(som)
	musica = AudioStreamPlayer.new()
	musica.stream = load("res://assets/Ninja Adventure - Asset Pack/Audio/Musics/21 - Dungeon.ogg")
	musica.set("parameters/looping",1)
	musica.volume_db = -27
	add_child(musica)
	musica.play()
	get_viewport().size_changed.connect(_ajustar_camera)
	_ajustar_camera()
	_atualizar_objetivo()
	_boas_vindas.call_deferred()

func _boas_vindas() -> void:
	while FluxoTela.em_transicao or HistoriaDupla.ativa:
		await get_tree().process_frame
	avisar(dados.dica)

func _ajustar_camera() -> void:
	_atualizar_camera(1.0)

func _atualizar_camera(delta: float) -> void:
	var janela := get_viewport_rect().size
	var separacao := (nico.position-otto.position).abs()
	var escala := clampf(minf(janela.x/(separacao.x+330),janela.y/(separacao.y+260)),0.65,1.25)
	$Camera.zoom = $Camera.zoom.lerp(Vector2.ONE*escala,minf(1,delta*3))
	var foco := (nico.position+otto.position)/2
	var metade: Vector2 = janela/$Camera.zoom/2
	var tamanho := Vector2(dados.tamanho)*24
	foco.x = clampf(foco.x,minf(metade.x,tamanho.x/2),maxf(tamanho.x-metade.x,tamanho.x/2))
	foco.y = clampf(foco.y,minf(metade.y,tamanho.y/2),maxf(tamanho.y-metade.y,tamanho.y/2))
	$Camera.position = $Camera.position.lerp(foco,minf(1,delta*4))

func avisar(mensagem: String) -> void:
	aviso.text = mensagem
	tempo_aviso = 4.0

func _som(caminho: String) -> void:
	if HistoriaDupla.silenciado:
		return
	som.stream = load(caminho)
	som.play()

func _physics_process(delta: float) -> void:
	_atualizar_camera(delta)
	tempo_aviso = maxf(0,tempo_aviso-delta)
	aviso.modulate.a = clampf(tempo_aviso/0.5,0,1)
	musica.stream_paused = HistoriaDupla.silenciado
	if has_node("PlacaNico"):
		var sobre: bool = _sobre(nico,$PlacaNico)
		if sobre != placa_ativa:
			placa_ativa = sobre
			_marcar_placa($PlacaNico,sobre)
			if not resolvida and (mapa_id == 1 or roda_ativa):
				avisar("O cristal acendeu! Otto, é sua vez." if sobre else "O cristal desativou. Nico pode voltar para a pedra.")
	if mapa_id == 1:
		var sobre_otto := _sobre(otto,$PlacaOtto)
		if sobre_otto != ajuda_otto:
			ajuda_otto = sobre_otto
			_marcar_placa($PlacaOtto,sobre_otto)
			if resolvida and not roda_ativa:
				avisar("Otto segura a pedra! Nico, golpeie a trava com F." if sobre_otto else "Otto pode voltar à pedra para ajudar Nico.")
	if mapa_id == 2:
		for i in 3:
			if not pistas_lidas.has(i) and nico.position.distance_to(Vector2(dados.pistas[i])*24+Vector2(12,12)) < 48:
				pistas_lidas[i] = true
				get_node("Pistas/Pista%d"%i).modulate.a = 1
				avisar(["Nico: Primeiro, o triângulo!","Nico: Depois, o círculo!","Nico: Por último, o quadrado!"][i])
				_som("res://assets/SONS/INTERFACE/SELECAO/KENNEY_INTERFACE_SOUNDS/select_001.ogg")
				ocioso = 0
				_atualizar_objetivo()
	for alvo in $Alvos.get_children():
		alvo.ativo = _alvos_liberados()
	if mapa_id == 4 and resolvida and not pronta:
		var placas := $PlacasFinais.get_children()
		if placas[0].pressed and placas[1].pressed:
			for placa in placas:
				placa.single_use = true
			_preparar_saida()
	for i in dados.segredos.size():
		if achados.has(i):
			continue
		var p := Vector2(dados.segredos[i])*24+Vector2(12,12)
		if minf(nico.position.distance_to(p),otto.position.distance_to(p)) < 22:
			achados[i] = true
			avisar("Uma joia escondida! Belo trabalho de exploração, dupla!")
			$Segredos.get_child(i).modulate = Color("#fff3a0")
			_som("res://assets/SONS/INTERFACE/SELECAO/KENNEY_INTERFACE_SOUNDS/select_001.ogg")
	ocioso += delta
	if ocioso > 25 and not dica_dada and not pronta:
		dica_dada = true
		avisar(_dica_atual())

func _sobre(heroi: Heroi, pedra: Node2D) -> bool:
	return heroi.position.distance_to(pedra.position) < 18 and not heroi.pulando and not heroi.esta_morto

func _marcar_placa(pedra: Node, pressionada: bool) -> void:
	pedra.bodies_on_button = 1 if pressionada else 0
	if pressionada: pedra._press()
	else: pedra._release()
	_som("res://assets/SONS/INTERFACE/CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg")

func pode_acionar_roda() -> bool:
	if mapa_id == 1 and (not resolvida or not ajuda_otto):
		avisar("Primeiro libertem Otto. Depois, ele segura a pedra da sala para Nico.")
		return false
	return true

func acionar_roda() -> void:
	roda_ativa = true
	ocioso = 0
	dica_dada = false
	_som("res://assets/SONS/CENARIO/PONTE/ponte_mecanismo.wav")
	if mapa_id == 1:
		animando = true
		await _abrir_grade($GradeFinal)
		animando = false
		_preparar_saida()
	elif mapa_id == 2:
		avisar("Os alvos despertaram! Nico lê as pistas; Otto testa os símbolos.")
	else:
		var t := create_tween()
		t.tween_property($Espelho,"rotation",-PI/4,0.75).set_trans(Tween.TRANS_SINE)
		avisar("O espelho virou! Nico fica na pedra; Otto carrega a esfera na outra ala.")
	_atualizar_objetivo()

func _dica_atual() -> String:
	if mapa_id == 1 and resolvida:
		return "Otto, a pedra da sala é sua vez de ajudar! Nico usa F na trava."
	if mapa_id == 2:
		if not roda_ativa: return "Nico, procure a trava no centro da cisterna. Use F perto dela."
		return ["Procurem a primeira pista na alcova da esquerda: triângulo.","A segunda pista fica na galeria de cima: círculo.","A última pista fica na ponta da galeria: quadrado."][mini(progresso,2)]
	if mapa_id == 4 and not roda_ativa:
		return "Nico, a trava fica na sala acima da sua pedra. Use F para virar o espelho."
	return dados.dica

func _alvos_liberados() -> bool:
	if resolvida: return false
	match mapa_id:
		1: return placa_ativa
		2: return roda_ativa
		4: return placa_ativa and roda_ativa
	return false

func alvo_atingido(indice_alvo: int) -> void:
	if not _alvos_liberados():
		return
	ocioso = 0
	if mapa_id == 2:
		var ordem := [1,0,2]
		if not pistas_lidas.has(progresso):
			avisar(_dica_atual())
			return
		if indice_alvo != ordem[progresso]:
			erros_sequencia += 1
			avisar("Esse não é o próximo símbolo. Os acertos continuam guardados!" if erros_sequencia < 3 else _dica_atual())
			_som("res://assets/SONS/INTERFACE/OUTROS/KENNEY_INTERFACE_SOUNDS/tick_001.ogg")
			_atualizar_objetivo()
			return
	$Alvos.get_child(indice_alvo).confirmado = true
	progresso += 1
	_som("res://assets/SONS/INTERFACE/SELECAO/KENNEY_INTERFACE_SOUNDS/select_001.ogg")
	_atualizar_objetivo()
	if mapa_id != 2 or progresso == 3:
		resolvida = true
		_atualizar_objetivo()
		_abrir_passagem()

func _atualizar_objetivo() -> void:
	var status := "Nico na pedra · Otto no alvo"
	if mapa_id == 2:
		var marcas: Array[String] = []
		for i in 3:
			marcas.append(["△","○","□"][i] if pistas_lidas.has(i) else "?")
		status = "Pistas: %s · %d / 3"%[" → ".join(marcas),progresso]
	if resolvida:
		status = "Uma pedra para cada amigo" if mapa_id == 4 else "Abrindo a passagem..."
		if mapa_id == 1 and not roda_ativa: status = "Otto na pedra · Nico na trava (F)"
	elif mapa_id == 4 and not roda_ativa:
		status = "Nico: preparar o espelho na ala esquerda"
	if pronta:
		status = "Saída: cheguem juntos ao círculo"
	objetivo.text = "%d / 4 · %s\n%s"%[mapa_id,dados.nome,status]

func _abrir_passagem() -> void:
	animando = true
	avisar("Conseguimos! Esperem o mecanismo terminar de abrir.")
	_som("res://assets/SONS/CENARIO/PONTE/ponte_mecanismo.wav")
	if mapa_id == 2:
		await _erguer_ponte()
		$BloqueioPonte/shape.set_deferred("disabled",true)
	else:
		await _abrir_grade($Grade)
	animando = false
	if mapa_id == 4:
		avisar("Agora, uma pedra para cada amigo na sala da porta!")
	elif mapa_id == 1:
		avisar("Otto está livre! Agora ele segura a pedra para Nico abrir a última grade.")
		ocioso = 0
		dica_dada = false
	else:
		_preparar_saida()

func _abrir_grade(grupo: Node) -> void:
	for parte in grupo.get_children():
		parte.definir_ativado(true)
	await get_tree().create_timer(1.2,false).timeout

func _erguer_ponte() -> void:
	# Lajes sobem uma a uma; a colisão continua fechada até a última encaixar.
	var ponte: TileMapLayer = $Ponte
	var r: Rect2i = dados.ponte
	var lajes: Array[TileMapLayer] = []
	for x in range(r.position.x,r.end.x):
		var laje := TileMapLayer.new()
		laje.tile_set = ponte.tile_set
		laje.scale = ponte.scale
		laje.z_index = -3
		laje.position.y = 14
		for y in range(r.position.y,r.end.y):
			var p := Vector2i(x,y)
			laje.set_cell(p,ponte.get_cell_source_id(p),ponte.get_cell_atlas_coords(p))
		add_child(laje)
		lajes.append(laje)
		var t := create_tween().set_parallel(true)
		t.tween_property(laje,"position:y",0.0,0.28).set_trans(Tween.TRANS_BACK)
		t.tween_property(laje,"modulate:a",1.0,0.28).from(0.25)
		await t.finished
	ponte.show()
	for laje in lajes:
		laje.queue_free()

func _preparar_saida() -> void:
	if pronta or animando:
		return
	pronta = true
	_atualizar_objetivo()
	var luz := create_tween()
	luz.tween_property($LuzSaida,"energy",1.0,1.1)
	$Porta.play("abrir")
	await $Porta.animation_finished
	$Saida.set_deferred("monitoring",true)
	avisar("A porta abriu! Cheguem juntos ao círculo de saída.")

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event.is_action_pressed("alternar_audio"):
		HistoriaDupla.silenciado = not HistoriaDupla.silenciado
