extends Node2D
## Uma paisagem sonora por sala, com sons existentes e eventos espaçados.
signal evento_ambiente(tipo: StringName)
const MAPAS = preload("res://recursos/mapas_puzzle.gd")
const VENTO = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Sounds/Ambient/Wind2.wav")
const AGUA = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Sounds/Ambient/River.wav")
const GOTA = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Sounds/Elemental/WaterDrop.wav")
const RANGIDOS: Array[AudioStream] = [
	preload("res://assets/SONS/AMBIENTE/PORTAS_E_RANGIDOS/KENNEY_RPG_AUDIO/creak1.ogg"),
	preload("res://assets/SONS/AMBIENTE/PORTAS_E_RANGIDOS/KENNEY_RPG_AUDIO/creak2.ogg"),
	preload("res://assets/SONS/AMBIENTE/PORTAS_E_RANGIDOS/KENNEY_RPG_AUDIO/creak3.ogg")]
const MUSICA = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Musics/21 - Dungeon.ogg")
var fase := 1
var aleatorio := RandomNumberGenerator.new()
var ar: AudioStreamPlayer
var agua: AudioStreamPlayer
var musica: AudioStreamPlayer
var gotas: Array[AudioStreamPlayer2D] = []
var rangido: AudioStreamPlayer2D
var fontes: Array[Vector2] = []
var zonas_agua: Array[Rect2] = []
var herois: Array[Node] = []
var proxima_gota := 1.5
var proximo_rangido := 14.0
var ultima_fonte := -1
var ultimo_rangido := -1
var tempo := 0.0
var entrada := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	aleatorio.randomize()
	fase = int(get_parent().fase_historia)
	_preparar_buses()
	_localizar_fontes()
	herois = get_tree().get_nodes_in_group("herois")
	ar = _camada(VENTO, &"ArMasmorra")
	ar.pitch_scale = 0.68
	agua = _camada(AGUA, &"AmbMasmorra")
	agua.pitch_scale = 0.88
	musica = _camada(MUSICA, &"MusicaMasmorra")
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
	if MAPAS.FASES.has(fase):
		for zona: Rect2i in MAPAS.FASES[fase].agua:
			var retangulo := Rect2(Vector2(zona.position) * 24, Vector2(zona.size) * 24)
			zonas_agua.append(retangulo)
			fontes.append(retangulo.get_center())
	else:
		# A fase 3 tem abismos, não um rio: só infiltrações nas paredes.
		var terreno: TileMapLayer = get_parent().get_node("Terrain map layer")
		var limites := terreno.get_used_rect()
		for fracao in [Vector2(0.15, 0.20), Vector2(0.85, 0.25), Vector2(0.25, 0.80), Vector2(0.75, 0.75)]:
			var celula := limites.position + Vector2i(Vector2(limites.size) * fracao)
			fontes.append(to_local(terreno.to_global(terreno.map_to_local(celula))))

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
	for audio in [ar, agua, musica]:
		audio.stream_paused = suspenso or HistoriaDupla.silenciado
	for gota in gotas:
		gota.stream_paused = suspenso or HistoriaDupla.silenciado or lendo
	rangido.stream_paused = suspenso or HistoriaDupla.silenciado or lendo
	if suspenso or HistoriaDupla.silenciado:
		return
	tempo += delta
	entrada = minf(1.0, entrada + delta / 2.5)
	var leitura_db := -8.0 if lendo else 0.0
	var atenuacao := linear_to_db(maxf(0.001, entrada))
	ar.volume_db = lerpf(ar.volume_db, -24.0 + sin(tempo * 0.21) * 1.3 + leitura_db + atenuacao, minf(1, delta * 2))
	musica.volume_db = lerpf(musica.volume_db, -25.0 + leitura_db + atenuacao, minf(1, delta * 3))
	var proximidade := _proximidade_agua()
	var volume_agua := lerpf(-38.0, -24.0 if fase == 2 else -30.0, proximidade)
	if zonas_agua.is_empty():
		volume_agua = -70
	agua.volume_db = lerpf(agua.volume_db, volume_agua + leitura_db + atenuacao, minf(1, delta * 2))
	if lendo:
		return
	proxima_gota -= delta
	proximo_rangido -= delta
	if proxima_gota <= 0:
		_emitir_gota()
		proxima_gota = aleatorio.randf_range(0.9, 3.2) if fase == 2 else aleatorio.randf_range(2.0, 5.5)
	if proximo_rangido <= 0:
		_emitir_rangido()
		proximo_rangido = aleatorio.randf_range(16.0, 32.0)

func _proximidade_agua() -> float:
	var distancia := 900.0
	for heroi in herois:
		if not is_instance_valid(heroi):
			continue
		for zona in zonas_agua:
			var ponto := to_local(heroi.global_position)
			var margem := ponto.clamp(zona.position, zona.end)
			distancia = minf(distancia, ponto.distance_to(margem))
	return 1.0 - smoothstep(40.0, 400.0, distancia)

func _emitir_gota() -> void:
	if fontes.is_empty():
		return
	for gota in gotas:
		if gota.playing:
			continue
		var indice := aleatorio.randi_range(0, fontes.size() - 1)
		if fontes.size() > 1 and indice == ultima_fonte:
			indice = (indice + 1) % fontes.size()
		ultima_fonte = indice
		gota.position = fontes[indice] + Vector2(aleatorio.randf_range(-12, 12), 0)
		gota.pitch_scale = aleatorio.randf_range(0.82, 1.16)
		gota.volume_db = aleatorio.randf_range(-17, -13)
		gota.play()
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
