extends BaseArea
const MAPAS = preload("res://recursos/mapas_puzzle.gd")
@export var mapa_id := 1
var dados: Dictionary
var pronta := false
var resolvida := false
var animando := false
var progresso := 0
var placa_ativa := false
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
	$PlacaNico/hitbox.collision_mask = 0
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
	var janela := get_viewport_rect().size
	$Camera.zoom = Vector2.ONE*minf(janela.x/800.0,janela.y/552.0)

func avisar(mensagem: String) -> void:
	aviso.text = mensagem
	tempo_aviso = 4.0

func _som(caminho: String) -> void:
	if HistoriaDupla.silenciado:
		return
	som.stream = load(caminho)
	som.play()

func _physics_process(delta: float) -> void:
	tempo_aviso = maxf(0,tempo_aviso-delta)
	aviso.modulate.a = clampf(tempo_aviso/0.5,0,1)
	musica.stream_paused = HistoriaDupla.silenciado
	var sobre: bool = nico.global_position.distance_to($PlacaNico.global_position) < 18 and not nico.pulando and not nico.esta_morto
	if sobre != placa_ativa:
		placa_ativa = sobre
		$PlacaNico.bodies_on_button = 1 if sobre else 0
		if sobre:
			$PlacaNico._press()
		else:
			$PlacaNico._release()
		if not resolvida:
			avisar("O alvo apareceu! Otto, é sua vez." if sobre else "O alvo guardou. Nico pode voltar para a pedra.")
			_som("res://assets/SONS/INTERFACE/CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg")
	for alvo in $Alvos.get_children():
		alvo.ativo = placa_ativa and not resolvida
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
		avisar(dados.dica)

func alvo_atingido(indice_alvo: int) -> void:
	if resolvida or not placa_ativa:
		return
	ocioso = 0
	if mapa_id == 2:
		var ordem := [1,0,2]
		if indice_alvo != ordem[progresso]:
			progresso = 0
			for alvo in $Alvos.get_children():
				alvo.confirmado = false
			avisar("Quase! Vamos olhar a pista: 2, depois 1 e depois 3. Pode tentar de novo!")
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
		status = "Ordem: 2 → 1 → 3 · %d / 3"%progresso
	if resolvida:
		status = "Uma pedra para cada amigo" if mapa_id == 4 else "Abrindo a passagem..."
	if pronta:
		status = "Saída: cheguem juntos ao círculo"
	objetivo.text = "%d / 4 · %s\n%s"%[mapa_id,dados.nome,status]

func _abrir_passagem() -> void:
	animando = true
	avisar("Conseguimos! Esperem o mecanismo terminar de abrir.")
	_som("res://assets/SONS/CENARIO/PONTE/ponte_mecanismo.wav")
	if mapa_id == 2:
		$Ponte.show()
		$Ponte.modulate.a = 0
		$Ponte.position.y = -10
		var tween := create_tween().set_parallel(true)
		tween.tween_property($Ponte,"modulate:a",1.0,0.9)
		tween.tween_property($Ponte,"position:y",0.0,1.2).set_trans(Tween.TRANS_BOUNCE)
		await tween.finished
		$BloqueioPonte/shape.set_deferred("disabled",true)
	else:
		for parte in $Grade.get_children():
			parte.definir_ativado(true)
		await get_tree().create_timer(1.2,false).timeout
	animando = false
	if mapa_id == 4:
		avisar("Agora, uma pedra para cada amigo na sala da porta!")
	else:
		_preparar_saida()

func _preparar_saida() -> void:
	if pronta or animando:
		return
	pronta = true
	_atualizar_objetivo()
	$Porta.play("abrir")
	await $Porta.animation_finished
	$Saida.set_deferred("monitoring",true)
	avisar("A porta abriu! Cheguem juntos ao círculo de saída.")

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event.is_action_pressed("alternar_audio"):
		HistoriaDupla.silenciado = not HistoriaDupla.silenciado
