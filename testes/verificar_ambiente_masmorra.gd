extends SceneTree
var erros := 0
var total := 0
var eventos: Array[StringName] = []

func _initialize() -> void:
	call_deferred("executar")

func conferir(condicao: bool, mensagem: String) -> void:
	total += 1
	if not condicao:
		erros += 1
		push_error(mensagem)

func executar() -> void:
	var historia = root.get_node("HistoriaDupla")
	var fases := ["puzzle_01", "puzzle_02", "area_3", "puzzle_04"]
	var numero_buses := -1
	for i in fases.size():
		historia.fase = i + 1
		historia.vistos["entrada_%d" % (i + 1)] = true
		change_scene_to_file("res://cenas/areas/%s.tscn" % fases[i])
		await process_frame
		await process_frame
		# Diálogos pausam o mundo; o teste continua sem alterar a história.
		if historia.ativa:
			historia.finalizar()
		paused = false
		var ambiente = current_scene.get_node("AmbienteMasmorra")
		conferir(ambiente.fase == i + 1, "Perfil da fase %d" % (i + 1))
		conferir(ambiente.fontes.size() >= 2, "Fontes distribuídas pela sala")
		conferir(ambiente.gotas.size() == 3, "Pool limitado a três pingos")
		conferir(ambiente.ar.playing and ambiente.musica.playing, "Ar e música iniciam na fase")
		conferir(ambiente.ar.stream != ambiente.VENTO, "Loop não modifica o asset original")
		conferir(ambiente.ar.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Vento em loop contínuo")
		conferir(ambiente.musica.stream.loop, "Música em loop contínuo")
		conferir(ambiente.VENTO.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Original do vento preservado")
		if numero_buses < 0:
			numero_buses = AudioServer.bus_count
		conferir(AudioServer.bus_count == numero_buses, "Buses não se duplicam ao trocar de fase")
		if i == 2:
			conferir(ambiente.zonas_agua.is_empty(), "Abismos da fase 3 não recebem rio")
		else:
			conferir(not ambiente.zonas_agua.is_empty(), "Água usa regiões reais do mapa")
		ambiente.evento_ambiente.connect(func(tipo): eventos.append(tipo))
		ambiente.proxima_gota = 0
		await process_frame
		conferir(eventos.has(&"gota"), "Pingo dispara ao vencer intervalo")
		conferir(ambiente.proxima_gota > 0, "Próximo pingo é reagendado")
		var fonte_anterior: int = ambiente.ultima_fonte
		ambiente._emitir_gota()
		conferir(ambiente.ultima_fonte != fonte_anterior, "Dois pingos não repetem a mesma fonte")
		ambiente._emitir_rangido()
		conferir(ambiente.rangido.playing, "Rangido distante disponível")
		conferir(ambiente.rangido.volume_db < -25, "Rangido discreto sem sustos")
		var tempo_antes: float = ambiente.tempo
		var intervalo_antes: float = ambiente.proxima_gota
		paused = true
		await create_timer(0.1).timeout
		conferir(ambiente.ar.stream_paused and ambiente.musica.stream_paused, "Pausa suspende as camadas")
		conferir(is_equal_approx(tempo_antes, ambiente.tempo) and is_equal_approx(intervalo_antes, ambiente.proxima_gota), "Pausa congela agendamento")
		var tecla := InputEventAction.new()
		tecla.action = "alternar_audio"
		tecla.pressed = true
		Input.parse_input_event(tecla)
		await process_frame
		conferir(historia.silenciado, "M funciona mesmo pausado")
		conferir(AudioServer.is_bus_mute(AudioServer.get_bus_index("AmbMasmorra")), "M silencia eco e pingos")
		conferir(AudioServer.is_bus_mute(AudioServer.get_bus_index("MusicaMasmorra")), "M silencia música")
		conferir(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "M silencia ações e passos")
		Input.parse_input_event(tecla)
		await process_frame
		conferir(not historia.silenciado, "M restaura o som sem dupla alternância")
		paused = false
		await process_frame
		conferir(not ambiente.ar.stream_paused, "Retomar libera a ambientação")
		if i == 1:
			var heroi: Node2D = current_scene.nico
			var posicao_anterior := heroi.global_position
			heroi.global_position = ambiente.zonas_agua[0].get_center()
			conferir(ambiente._proximidade_agua() > 0.99, "Rio ganha presença junto à água")
			heroi.global_position = posicao_anterior
		var referencia: WeakRef = weakref(ambiente)
		current_scene.queue_free()
		await process_frame
		await process_frame
		conferir(referencia.get_ref() == null, "Sons pertencem à fase e são liberados na saída")
		eventos.clear()
	var bus := AudioServer.get_bus_index("AmbMasmorra")
	conferir(AudioServer.get_bus_effect_count(bus) == 1, "Uma reverberação compartilhada")
	conferir(AudioServer.get_bus_effect(bus, 0) is AudioEffectReverb, "Eco de sala real no mixer")
	print("AMBIENTE_MASMORRA: %d verificações, %d falhas" % [total, erros])
	await create_timer(0.25).timeout
	quit(0 if erros == 0 else 1)
