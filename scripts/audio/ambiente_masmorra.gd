extends Node2D
## Uma paisagem sonora por sala, com sons existentes e eventos espaçados.
signal evento_ambiente(tipo: StringName)
const VENTO = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Sounds/Ambient/Wind2.wav")
const GOTA = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Sounds/Elemental/WaterDrop.wav")
const RANGIDOS: Array[AudioStream] = [
	preload("res://assets/SONS/AMBIENTE/PORTAS_E_RANGIDOS/KENNEY_RPG_AUDIO/creak1.ogg"),
	preload("res://assets/SONS/AMBIENTE/PORTAS_E_RANGIDOS/KENNEY_RPG_AUDIO/creak2.ogg"),
	preload("res://assets/SONS/AMBIENTE/PORTAS_E_RANGIDOS/KENNEY_RPG_AUDIO/creak3.ogg")]
const MUSICA = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Musics/21 - Dungeon.ogg")
const GALERIA := "res://assets/SONS/AMBIENTE/MASMORRA/galeria_das_plataformas.wav"
const SAIDA := "res://assets/SONS/AMBIENTE/MASMORRA/caminho_da_saida.wav"
const BRASA := "res://assets/SONS/AMBIENTE/MASMORRA/brasa_tocha.wav"
var brasas: Array[AudioStreamPlayer2D] = []
var posicoes_tochas := PackedVector2Array()
var atualizar_brasas_em := 0.0
var fase := 1
var aleatorio := RandomNumberGenerator.new()
var ar: AudioStreamPlayer
var musica: AudioStreamPlayer
var gotas: Array[AudioStreamPlayer2D] = []
var rangido: AudioStreamPlayer2D
var fontes: Array[Vector2] = []
var proxima_gota := 1.5
var proximo_rangido := 14.0
var ultima_fonte := -1
const QUEDA_GOTA := 0.34
var ponto_da_gota := Vector2.ZERO
var gota_pendente: AudioStreamPlayer2D
var impacto_em := 0.0
var ultimo_rangido := -1
var tempo := 0.0
var entrada := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	aleatorio.randomize()
	fase = int(get_parent().fase_historia)
	_preparar_buses()
	_localizar_fontes()
	ar = _camada(VENTO, &"ArMasmorra")
	ar.pitch_scale = 0.68
	var trilha: AudioStream = MUSICA
	if fase == 2:
		trilha = load(GALERIA)
	elif fase == 3:
		trilha = load(SAIDA)
	musica = _camada(trilha, &"MusicaMasmorra")
	for i in 3:
		var gota := _fonte()
		gota.stream = GOTA
		gotas.append(gota)
	rangido = _fonte()
	proxima_gota = aleatorio.randf_range(1.0, 2.5)
	proximo_rangido = aleatorio.randf_range(12.0, 22.0)
	_sincronizar_silencio()

func _preparar_buses() -> void:
	# Os buses são reutilizados nas transições, sem empilhar efeitos a cada fase.
	if AudioServer.get_bus_index("AmbMasmorra") < 0:
		AudioServer.add_bus()
		var indice := AudioServer.bus_count - 1
		AudioServer.set_bus_name(indice, "AmbMasmorra")
		AudioServer.set_bus_send(indice, "Master")
		var eco := AudioEffectReverb.new()
		eco.room_size = 0.78
		eco.damping = 0.64
		eco.wet = 0.24
		eco.dry = 0.9
		eco.predelay_msec = 95
		AudioServer.add_bus_effect(indice, eco)
	if AudioServer.get_bus_index("ArMasmorra") < 0:
		AudioServer.add_bus()
		var indice := AudioServer.bus_count - 1
		AudioServer.set_bus_name(indice, "ArMasmorra")
		AudioServer.set_bus_send(indice, "AmbMasmorra")
		var filtro := AudioEffectLowPassFilter.new()
		filtro.cutoff_hz = 850
		AudioServer.add_bus_effect(indice, filtro)
	if AudioServer.get_bus_index("MusicaMasmorra") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "MusicaMasmorra")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")

func _localizar_fontes() -> void:
	var campo := get_parent().get_node_or_null("HoleField") as HoleField
	if campo == null or campo.tile_map_layer == null:
		return
	var terreno := campo.tile_map_layer
	# Localiza infiltrações junto às paredes, em pisos de verdade.
	var celulas := terreno.get_used_cells()
	celulas.sort()
	for celula in celulas:
		var piso := terreno.get_cell_tile_data(celula)
		if piso.get_collision_polygons_count(0) > 0 or piso.get_collision_polygons_count(campo.scan_physics_layer) > 0:
			continue
		var margem := false
		for direcao in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
			var parede := terreno.get_cell_tile_data(celula + direcao)
			if parede == null or parede.get_collision_polygons_count(0) > 0:
				margem = true
				break
		if not margem:
			continue
		var ponto := to_local(terreno.to_global(terreno.map_to_local(celula)))
		if fontes.any(func(fonte: Vector2) -> bool: return fonte.distance_squared_to(ponto) < 210.0 * 210.0):
			continue
		fontes.append(ponto)
		if fontes.size() >= 20:
			break

func _camada(stream: AudioStream, bus: StringName) -> AudioStreamPlayer:
	var audio := AudioStreamPlayer.new()
	# Somente a cópia local recebe loop; o asset usado por outros sistemas é preservado.
	audio.stream = stream.duplicate()
	if audio.stream is AudioStreamWAV:
		var wav := audio.stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif audio.stream is AudioStreamOggVorbis:
		(audio.stream as AudioStreamOggVorbis).loop = true
	audio.bus = bus
	audio.volume_db = -60
	add_child(audio)
	audio.play()
	return audio

func definir_tochas(locais: PackedVector2Array) -> void:
	posicoes_tochas = locais.duplicate()
	if posicoes_tochas.is_empty():
		return
	var fogo := (load(BRASA) as AudioStreamWAV).duplicate() as AudioStreamWAV
	fogo.loop_mode = AudioStreamWAV.LOOP_FORWARD
	fogo.loop_end = roundi(fogo.get_length() * fogo.mix_rate)
	for i in mini(posicoes_tochas.size(), 2):
		var brasa := _fonte()
		brasa.stream = fogo
		brasa.volume_db = -19.0
		brasa.max_distance = 330.0
		brasa.attenuation = 0.82
		brasa.pitch_scale = 0.92 + i * 0.10
		brasas.append(brasa)
		brasa.play(float(i) * 1.25)
	_aproximar_brasas()

func _aproximar_brasas() -> void:
	var camera := get_viewport().get_camera_2d()
	var centro := camera.get_screen_center_position() if camera else Vector2.ZERO
	var locais: Array[Vector2] = []
	locais.assign(Array(posicoes_tochas))
	locais.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.distance_squared_to(centro) < b.distance_squared_to(centro))
	for i in brasas.size():
		brasas[i].global_position = locais[i]

func _fonte() -> AudioStreamPlayer2D:
	var audio := AudioStreamPlayer2D.new()
	audio.bus = &"AmbMasmorra"
	audio.max_distance = 1200
	audio.attenuation = 0.65
	audio.panning_strength = 0.65
	add_child(audio)
	return audio

func _sincronizar_silencio() -> void:
	for nome_bus in ["AmbMasmorra", "MusicaMasmorra", "SFX"]:
		var indice := AudioServer.get_bus_index(nome_bus)
		if indice >= 0 and AudioServer.is_bus_mute(indice) != HistoriaDupla.silenciado:
			AudioServer.set_bus_mute(indice, HistoriaDupla.silenciado)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("alternar_audio") and not event.is_echo():
		HistoriaDupla.silenciado = not HistoriaDupla.silenciado
		_sincronizar_silencio()
		# Um único responsável por M, inclusive na fase 3 e no menu de pausa.
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_sincronizar_silencio()
	var lendo: bool = HistoriaDupla.ativa
	var suspenso: bool = FluxoTela.em_transicao or (get_tree().paused and not lendo)
	for audio in [ar, musica]:
		audio.stream_paused = suspenso or HistoriaDupla.silenciado
	for brasa in brasas:
		brasa.stream_paused = suspenso or HistoriaDupla.silenciado or lendo
	for gota in gotas:
		gota.stream_paused = suspenso or HistoriaDupla.silenciado or lendo
	rangido.stream_paused = suspenso or HistoriaDupla.silenciado or lendo
	if suspenso:
		return
	tempo += delta
	entrada = minf(1.0, entrada + delta / 2.5)
	var leitura_db := -8.0 if lendo else 0.0
	var atenuacao := linear_to_db(maxf(0.001, entrada))
	ar.volume_db = lerpf(ar.volume_db, -24.0 + sin(tempo * 0.21) * 1.3 + leitura_db + atenuacao, minf(1, delta * 2))
	var volume_trilha := -25.0 if fase == 1 else -17.0
	musica.volume_db = lerpf(musica.volume_db, volume_trilha + leitura_db + atenuacao, minf(1, delta * 3))
	atualizar_brasas_em -= delta
	if atualizar_brasas_em <= 0.0 and not brasas.is_empty():
		_aproximar_brasas()
		atualizar_brasas_em = 0.50
	if lendo:
		return
	if is_instance_valid(gota_pendente):
		impacto_em -= delta
		if impacto_em <= 0.0:
			if not HistoriaDupla.silenciado:
				gota_pendente.play()
			evento_ambiente.emit(&"impacto_gota")
			gota_pendente = null
	proxima_gota -= delta
	proximo_rangido -= delta
	if proxima_gota <= 0:
		_emitir_gota()
		proxima_gota = aleatorio.randf_range(0.9, 3.2) if fase == 2 else aleatorio.randf_range(2.0, 5.5)
	if proximo_rangido <= 0:
		if not HistoriaDupla.silenciado:
			_emitir_rangido()
		proximo_rangido = aleatorio.randf_range(13.0, 25.0) if fase != 2 else aleatorio.randf_range(24.0, 37.0)



func _emitir_gota() -> void:
	if fontes.is_empty() or is_instance_valid(gota_pendente):
		return
	for gota in gotas:
		if gota.playing:
			continue
		var indice := aleatorio.randi_range(0, fontes.size() - 1)
		if fontes.size() > 1 and indice == ultima_fonte:
			indice = (indice + 1) % fontes.size()
		ultima_fonte = indice
		gota.position = fontes[indice] + Vector2(aleatorio.randi_range(-10, 10), 0)
		ponto_da_gota = gota.position
		gota.pitch_scale = aleatorio.randf_range(0.82, 1.16)
		gota.volume_db = aleatorio.randf_range(-17, -13)
		gota_pendente = gota
		impacto_em = QUEDA_GOTA
		evento_ambiente.emit(&"gota")
		return

func _emitir_rangido() -> void:
	if rangido.playing or fontes.is_empty():
		return
	var indice := aleatorio.randi_range(0, RANGIDOS.size() - 1)
	if indice == ultimo_rangido:
		indice = (indice + 1) % RANGIDOS.size()
	ultimo_rangido = indice
	rangido.stream = RANGIDOS[indice]
	rangido.position = fontes[aleatorio.randi_range(0, fontes.size() - 1)]
	rangido.pitch_scale = aleatorio.randf_range(0.70, 0.86)
	rangido.volume_db = -26
	rangido.play()
	evento_ambiente.emit(&"rangido")

func _exit_tree() -> void:
	for audio in get_children():
		if audio is AudioStreamPlayer or audio is AudioStreamPlayer2D:
			audio.stop()
			audio.stream = null
