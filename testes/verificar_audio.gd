extends SceneTree
## Exercita as fontes de áudio que a campanha realmente instancia.
var falhas := 0
var total := 0

func _initialize() -> void:
	create_timer(25.0).timeout.connect(func(): push_error("Tempo limite ao verificar áudio"); quit(2))
	call_deferred("_executar")

func _conferir(condicao: bool, descricao: String) -> void:
	total += 1
	if not condicao:
		falhas += 1
		push_error(descricao)

func _executar() -> void:
	var historia := root.get_node("HistoriaDupla")
	var duracoes: Array[float] = []
	for fase in range(1, 4):
		change_scene_to_file("res://cenas/areas/area_%d.tscn" % fase)
		await scene_changed
		await create_timer(0.65).timeout
		historia.finalizar()
		await process_frame
		var ambiente := current_scene.get_node("AmbienteMasmorra")
		var acabamento := current_scene.get_node("AcabamentoMasmorra")
		var trilha: AudioStream = ambiente.musica.stream
		_conferir(ambiente.musica.playing and trilha.get_length() > 10.0, "A fase %d tem música" % fase)
		duracoes.append(trilha.get_length())
		_conferir(AudioServer.get_bus_index("AmbMasmorra") >= 0, "O ambiente tem um canal de áudio próprio")
		_conferir(ambiente.brasas.size() == 2 and ambiente.posicoes_tochas.size() == acabamento.luzes.size(),
			"As duas fontes de brasa seguem as arandelas existentes")
		var eventos: Array[StringName] = []
		ambiente.evento_ambiente.connect(func(evento: StringName): eventos.append(evento))
		ambiente.proxima_gota = 99.0
		ambiente._emitir_gota()
		_conferir(eventos == [&"gota"], "A queda começa antes do impacto")
		await create_timer(0.44).timeout
		_conferir(eventos == [&"gota", &"impacto_gota"] and not acabamento.ondas.is_empty(),
			"O impacto da gota coincide com a onda no chão")
		historia.silenciado = true
		await process_frame
		await process_frame
		_conferir(ambiente.musica.stream_paused and ambiente.brasas[0].stream_paused, "Silêncio pausa música e brasas")
		historia.silenciado = false
		await process_frame
		await process_frame
		_conferir(not ambiente.musica.stream_paused and not ambiente.brasas[0].stream_paused, "Restaurar o som retoma o ambiente")
	_conferir(duracoes[0] != duracoes[1] and duracoes[1] != duracoes[2] and duracoes[0] != duracoes[2],
		"As três salas usam trilhas distintas")
	print("AUDIO_CAMPANHA: ", total, " verificações, ", falhas, " falhas")
	current_scene.queue_free()
	await create_timer(0.15).timeout
	quit(int(falhas > 0))
