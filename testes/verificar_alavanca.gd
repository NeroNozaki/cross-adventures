extends SceneTree
var total := 0
var erros := 0

func _initialize() -> void:
	call_deferred("executar")

func conferir(ok: bool, texto: String) -> void:
	total += 1
	if not ok:
		erros += 1
		push_error(texto)

func executar() -> void:
	var historia = root.get_node("HistoriaDupla")
	for fase in [1,2,4]:
		change_scene_to_file("res://cenas/areas/puzzle_%02d.tscn" % fase)
		await process_frame
		await process_frame
		if historia.ativa:
			historia.finalizar()
		paused = false
		var trava = current_scene.get_node("MecanismoNico")
		var base: Sprite2D = trava.get_node("Imagem")
		var haste: Sprite2D = trava.get_node("Imagem/Haste")
		var posicao := base.position
		var escala := base.scale
		conferir(base.texture.region == Rect2(144,117,16,5), "Base separada da haste")
		conferir(haste.texture.region == Rect2(144,112,16,5), "Haste usa os pixels originais")
		if fase == 1:
			trava.receber_dano(1,Vector2.ZERO)
			conferir(not trava.acionada and haste.scale.x == 1, "Sem a ajuda de Otto não aciona")
			current_scene.resolvida = true
			current_scene.ajuda_otto = true
		trava.receber_dano(1,Vector2.ZERO)
		conferir(trava.acionada, "Golpe aceito aciona uma única vez")
		for i in 6:
			await create_timer(0.04).timeout
			conferir(is_zero_approx(base.rotation) and base.position == posicao and base.scale == escala, "Base fica completamente fixa")
			conferir(is_zero_approx(haste.rotation), "Haste troca de pose sem giro do sprite")
		conferir(haste.scale.x == -1, "Haste termina puxada para o outro lado")
		conferir(current_scene.roda_ativa, "Puzzle recebe a ativação ao encaixar")
		trava.receber_dano(1,Vector2.ZERO)
		conferir(haste.scale.x == -1, "Golpes repetidos não reiniciam o movimento")
		await create_timer(1.8).timeout
	current_scene.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("ALAVANCA: %d verificações, %d falhas" % [total,erros])
	quit(0 if erros == 0 else 1)
