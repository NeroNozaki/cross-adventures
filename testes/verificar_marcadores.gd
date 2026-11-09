extends SceneTree

var falhas: Array[String] = []
var total := 0


func _initialize() -> void:
	call_deferred("rodar")


func conferir(ok: bool, texto: String) -> void:
	total += 1
	if not ok:
		falhas.append(texto)
		push_error(texto)


func quadros() -> void:
	await physics_frame
	await process_frame
	await physics_frame


func rodar() -> void:
	AudioServer.set_bus_mute(0, true)
	for caminho in ["res://cenas/personagens/player1.tscn", "res://cenas/personagens/player2.tscn"]:
		var jogador: CharacterBody2D = load(caminho).instantiate()
		jogador.set_physics_process(false)
		root.add_child(jogador)
		await quadros()
		var marcador: Polygon2D = jogador.get_node("Marcador")
		conferir(marcador.visible, jogador.name + " comeca com marcador visivel")

		var posicao_local: Vector2 = marcador.position
		var posicao_global: Vector2 = marcador.global_position
		jogador.global_position += Vector2(10, 20)
		await process_frame
		conferir(marcador.global_position.is_equal_approx(posicao_global + Vector2(10, 20)), jogador.name + " marcador acompanha o jogador")
		conferir(marcador.position.is_equal_approx(posicao_local), jogador.name + " marcador mantem o deslocamento local")

		jogador.esta_morto = true
		jogador.atualizar_estado(0.016)
		conferir(not marcador.visible, jogador.name + " esconde o marcador morto")
		jogador.esta_morto = false
		jogador.atualizar_estado(0.016)
		conferir(marcador.visible, jogador.name + " reexibe o marcador vivo")

		jogador.free()
		await process_frame

	await create_timer(0.3).timeout

	if falhas.is_empty():
		print("MARCADORES_OK: %d verificacoes de acompanhamento e visibilidade." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
