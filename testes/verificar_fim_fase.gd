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
	conferir(root.has_node("FluxoTela") and root.get_node("FluxoTela").has_method("trocar"), "FluxoTela autoload is available")
	var fim: Area2D = load("res://cenas/objects/level_specifics/level_end.tscn").instantiate()
	fim.proxima_cena = ""
	fim.tempo_caminhada = 0.35
	fim.global_position = Vector2(200, 200)
	root.add_child(fim)

	var player1: CharacterBody2D = load("res://cenas/personagens/player1.tscn").instantiate()
	var player2: CharacterBody2D = load("res://cenas/personagens/player2.tscn").instantiate()
	root.add_child(player1)
	root.add_child(player2)
	player1.global_position = fim.global_position + Vector2(-100, 0)
	player2.global_position = fim.global_position + Vector2(100, 0)
	await quadros()

	player1.global_position = fim.global_position
	await quadros()
	conferir(not fim.foi_iniciado(), "one hero alone does not finish the level")

	player1.frente = Vector2.RIGHT
	player1.direcao = "right"
	player2.frente = Vector2.UP
	player2.direcao = "up"
	player2.global_position = fim.global_position + Vector2(4, 0)
	await quadros()
	conferir(fim.foi_iniciado(), "both heroes overlapping finish the level")
	conferir(not player1.controlado and not player2.controlado, "finishing disables both players' controls")
	conferir(not player1.is_physics_processing() and not player2.is_physics_processing(), "finishing stops player input processing")

	var inicio1: Vector2 = player1.global_position
	var inicio2: Vector2 = player2.global_position
	await create_timer(0.20).timeout
	conferir(player1.global_position.x > inicio1.x, "player1 keeps walking right during the exit")
	conferir(player2.global_position.y < inicio2.y, "player2 keeps walking up during the exit")
	conferir(fim.esta_caminhando(), "exit walk is still running with an empty destination")

	await create_timer(0.35).timeout
	conferir(not fim.esta_caminhando(), "exit walk stops after its duration")

	fim.free()
	player1.free()
	player2.free()
	await create_timer(0.5).timeout

	var alvo := "res://cenas/objects/interactables/button.tscn"
	var fim2: Area2D = load("res://cenas/objects/level_specifics/level_end.tscn").instantiate()
	fim2.proxima_cena = alvo
	fim2.tempo_caminhada = 0.20
	fim2.global_position = Vector2(600, 200)
	root.add_child(fim2)
	var player1b: CharacterBody2D = load("res://cenas/personagens/player1.tscn").instantiate()
	var player2b: CharacterBody2D = load("res://cenas/personagens/player2.tscn").instantiate()
	root.add_child(player1b)
	root.add_child(player2b)
	player1b.global_position = fim2.global_position + Vector2(-100, 0)
	player2b.global_position = fim2.global_position + Vector2(100, 0)
	await quadros()
	player1b.set_physics_process(false)
	player2b.set_physics_process(false)
	player1b.frente = Vector2.RIGHT
	player1b.direcao = "right"
	player2b.frente = Vector2.UP
	player2b.direcao = "up"
	player1b.global_position = fim2.global_position
	player2b.global_position = fim2.global_position + Vector2(4, 0)
	await quadros()
	conferir(fim2.foi_iniciado(), "second overlap starts the transition")
	conferir(paused, "transition starts together with the exit walk")
	var inicio1b: Vector2 = player1b.global_position
	var inicio2b: Vector2 = player2b.global_position
	await create_timer(0.12, true).timeout
	conferir(player1b.global_position.x > inicio1b.x, "player1 walks while the transition is running")
	conferir(player2b.global_position.y < inicio2b.y, "player2 walks while the transition is running")
	await create_timer(1.1, true).timeout
	conferir(current_scene != null and current_scene.scene_file_path == alvo, "FluxoTela loads the exported next scene")
	conferir(not paused, "tree resumes after the transition")
	fim2.free()
	player1b.free()
	player2b.free()
	await create_timer(0.5, true).timeout

	if falhas.is_empty():
		print("FIM_FASE_OK: %d verificacoes de sobreposicao dupla, bloqueio de controles, caminhada final e transicao." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
