extends SceneTree
var total := 0
var erros := 0

func _initialize() -> void:
	call_deferred("executar")

func conferir(condicao: bool, mensagem: String) -> void:
	total += 1
	if not condicao:
		erros += 1
		push_error(mensagem)

func executar() -> void:
	var historia = root.get_node("HistoriaDupla")
	for nome in ["puzzle_01", "puzzle_02", "area_3", "puzzle_04"]:
		change_scene_to_file("res://cenas/areas/%s.tscn" % nome)
		await process_frame
		await process_frame
		if historia.ativa:
			historia.finalizar()
		paused = false
		var acabamento = current_scene.get_node("AcabamentoMasmorra")
		conferir(acabamento.herois.size() == 2, "Duas sombras de contato: " + nome)
		conferir(acabamento.luzes.size() >= 1, "Tochas com luz animada: " + nome)
		conferir(acabamento.luzes.size() <= 12, "Luzes limitadas: " + nome)
		conferir(acabamento.cristais.size() >= 1, "Cristais existentes com brilho: " + nome)
		conferir(acabamento.vinheta.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Acabamento não intercepta cliques")
		conferir(acabamento.get_node("LuzAmbiente").color.r > 0.7, "Iluminação preserva leitura do cenário")
		if nome != "area_3":
			var reservatorio: TileMapLayer = current_scene.get_node("Reservatorios")
			conferir(reservatorio.material is ShaderMaterial, "Água com shader de profundidade")
			conferir(reservatorio.z_index < current_scene.get_node("Personagens").z_index, "Água fica atrás dos heróis")
		var heroi = acabamento.herois[0].no
		var inicio: Vector2 = heroi.position
		var formas: int = heroi.get_shape_owners().size()
		acabamento.celebrar(inicio, &"saida")
		conferir(acabamento.particulas.size() >= 16, "Partículas de confirmação visíveis")
		for i in 20:
			acabamento.celebrar(inicio, &"placa")
		conferir(acabamento.particulas.size() <= 96, "Efeitos respeitam o limite de partículas")
		conferir(heroi.position == inicio and heroi.get_shape_owners().size() == formas, "Efeitos não movem nem alteram colisão")
		var tempo_antes: float = acabamento.tempo
		paused = true
		await create_timer(0.08).timeout
		conferir(is_equal_approx(acabamento.tempo, tempo_antes), "Efeitos congelam na pausa")
		paused = false
		await create_timer(1.2).timeout
		conferir(acabamento.particulas.size() < 16, "Partículas temporárias desaparecem")
	var fluxo = root.get_node("FluxoTela")
	fluxo.trocar("res://cenas/screens/start_menu.tscn")
	fluxo.trocar("res://cenas/areas/puzzle_01.tscn")
	conferir(fluxo.em_transicao and paused, "Mosaico bloqueia comandos durante a transição")
	await create_timer(1.1).timeout
	conferir(current_scene.scene_file_path.ends_with("start_menu.tscn"), "Cliques repetidos não trocam o destino")
	conferir(not paused and not fluxo.cortina.visible, "Cortina libera a nova cena")
	current_scene._ajuda()
	current_scene._ajuda()
	await process_frame
	var guia := current_scene.get_node("GuiaControles")
	conferir(guia.visible and is_instance_valid(guia._guia), "Menu usa o mesmo guia visual da pausa")
	conferir(not paused, "Guia no menu não pausa a apresentação")
	guia._fechar_guia()
	await process_frame
	conferir(not current_scene.has_node("GuiaControles"), "Fechar o guia remove a camada")
	conferir(root.gui_get_focus_owner() == current_scene.menu.get_child(1), "Guia devolve foco ao botão do menu")
	current_scene.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("ACABAMENTO_MASMORRA: %d verificações, %d falhas" % [total, erros])
	quit(0 if erros == 0 else 1)
