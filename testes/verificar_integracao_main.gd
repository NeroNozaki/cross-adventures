extends SceneTree

const FIM := "res://cenas/screens/fim_aventura.tscn"
var falhas := 0
var total := 0
var historia: Node

func _initialize() -> void:
	call_deferred("_rodar")

func conferir(ok: bool, descricao: String) -> void:
	total += 1
	if not ok:
		falhas += 1
		push_error(descricao)

func _rodar() -> void:
	create_timer(45).timeout.connect(func(): push_error("Tempo limite"); quit(1))
	historia = root.get_node("HistoriaDupla")
	change_scene_to_file("res://cenas/screens/start_menu.tscn")
	await scene_changed
	await process_frame
	current_scene._on_play_pressed()
	await create_timer(1.3).timeout
	conferir(current_scene.name == &"EntradaAventura", "Jogar abre a cena animada")
	if falhas:
		quit(1)
		return
	current_scene.pular.pressed.emit()

	for num in range(1,4):
		await create_timer(1.2).timeout
		var sala := current_scene
		var esperado := "res://cenas/areas/area_%d.tscn" % num
		conferir(sala.scene_file_path == esperado, "Campanha deve chegar a " + esperado)
		if sala.scene_file_path != esperado:
			quit(1)
			return
		conferir(historia.fase == num and historia.ativa and paused, "Diálogo inicial da fase %d pausa a partida" % num)
		if num == 1:
			historia.avancar()
			conferir(historia.texto.visible_characters == -1, "Continuar revela o texto antes de trocar a fala")
			historia.avancar()
			conferir(historia.indice == 1, "Continuar avança para a próxima fala")
		historia.finalizar()
		await create_timer(0.4).timeout
		conferir(not paused, "Pular retoma os controles")
		var acabamento := sala.get_node("AcabamentoMasmorra")
		var ambiente := sala.get_node("AmbienteMasmorra")
		conferir(acabamento.herois.size() == 2 and acabamento.cristais.size() > 0, "Acabamento acompanha os heróis e cristais reais")
		conferir(acabamento.luzes.size() > 0 and acabamento.bordas.size() > 0, "Tochas e bordas calculadas a partir do mapa real")
		conferir(ambiente.musica.playing and not ambiente.fontes.is_empty(), "Ambiente identifica pontos de infiltração")
		conferir(sala.has_node("HUDCampanha"), "HUD em todos os mapas")
		if num == 2:
			var f1 := InputEventKey.new()
			f1.physical_keycode = KEY_F1
			f1.pressed = true
			Input.parse_input_event(f1)
		else:
			var botao := sala.find_child("AbrirGuia", true, false) as Button
			botao.pressed.emit()
		await create_timer(0.25).timeout
		conferir(paused and sala.esta_pausado(), "Pausa preserva o mapa atual")
		conferir(is_instance_valid(sala._pause_menu._guia), "O guia abre sobre a fase e mantém a pausa")
		sala._pause_menu.fechar()
		var saida := sala.get_node("level_end")
		var dupla := get_nodes_in_group("herois")
		# Exercita o gatilho da saída sem resolver os puzzles por teleporte.
		saida._on_body_entered(dupla[0])
		conferir(not saida.foi_iniciado(), "A saída exige os dois personagens")
		saida._on_body_entered(dupla[1])
		await process_frame
		conferir(historia.ativa and historia.pontos == num, "Diálogo de saída avança a amizade")
		historia.finalizar()

	await create_timer(1.2).timeout
	conferir(current_scene.scene_file_path == FIM and historia.pontos == 3, "Três fases completas levam à cena de comemoração")
	if current_scene.scene_file_path == FIM:
		current_scene.pular.pressed.emit()
		await process_frame
		conferir(current_scene.pronto, "Mensagem final pode ser lida")
		current_scene.voltar.pressed.emit()
		await create_timer(1.1).timeout
		conferir(current_scene.scene_file_path.ends_with("start_menu.tscn"), "Conclusão volta ao menu")
	print("INTEGRACAO_MAIN ", total, " verificações, ", falhas, " falhas")
	current_scene.queue_free()
	await create_timer(0.25).timeout
	quit(int(falhas > 0))
