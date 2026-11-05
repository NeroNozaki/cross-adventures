extends SceneTree

var failures: Array[String] = []
var total: int = 0

func _initialize() -> void:
	create_timer(20.0).timeout.connect(func():
		push_error("Timeout dos testes de dash e renascimento")
		quit(2)
	)
	call_deferred("run")

func check(ok: bool, text: String) -> void:
	total += 1
	if not ok:
		failures.append(text)
		push_error(text)

func wait_physics(count: int = 3) -> void:
	for _i in range(count):
		await physics_frame
	await process_frame

func make_hole(parent: Node, position: Vector2, size: Vector2 = Vector2(32, 32)) -> StaticBody2D:
	var hole: StaticBody2D = load("res://cenas/objects/hazards/hole.tscn").instantiate()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	hole.get_node("CollisionShape2D").shape = shape
	parent.add_child(hole)
	hole.global_position = position
	return hole

func run() -> void:
	AudioServer.set_bus_mute(0, true)
	check(PhysicsLayers.HOLES == 7, "layer de buracos usa o indice 7")
	check(ProjectSettings.get_setting("layer_names/2d_physics/layer_7") == "Buracos", "layer de buracos tem nome no projeto")

	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	check(InputMap.event_is_action(right_click, "player2_dash"), "clique direito aciona player2_dash")
	check(not InputMap.event_is_action(right_click, "player2_atacar"), "clique direito nao dispara o tiro")
	var left_click := InputEventMouseButton.new()
	left_click.button_index = MOUSE_BUTTON_LEFT
	check(InputMap.event_is_action(left_click, "player2_atacar") and not InputMap.event_is_action(left_click, "player2_dash"), "clique esquerdo continua apenas no tiro")

	var arena: Node2D = load("res://cenas/testes/arena_teste.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await wait_physics()
	var player1: CharacterBody2D = arena.get_node("Personagens/Player1")
	var player2: CharacterBody2D = arena.get_node("Personagens/Player2")
	var zumbi: CharacterBody2D = arena.get_node("Personagens/Zumbi")
	for actor in [player1, player2, arena.get_node("Personagens/CavaleiroAzul"), zumbi]:
		actor.set_physics_process(false)
	check(player1.get_collision_mask_value(PhysicsLayers.HOLES), "herois colidem com buracos")
	check(zumbi.get_collision_mask_value(PhysicsLayers.HOLES), "inimigos colidem com buracos")

	player1.global_position = Vector2(160, 180)
	player1.velocidade_controle = Vector2.ZERO
	player1.mover(Vector2.RIGHT, 1.0 / 60.0)
	check(absf(player1.velocidade_controle.x - player1.velocidade) < 0.01, "movimento atinge a velocidade no primeiro quadro")
	player1.mover(Vector2.ZERO, 1.0 / 60.0)
	check(player1.velocidade_controle.is_zero_approx() and player1.velocity.is_zero_approx(), "soltar o comando para imediatamente")

	player2.nome_personagem = "Personagem"
	player2.global_position = Vector2(240, 200)
	player2.atacando = true
	player2.tempo_ataque = 1.0
	var antes_tiro: Vector2 = player2.global_position
	player2.mover(Vector2.RIGHT, 1.0 / 60.0)
	check(player2.global_position.x > antes_tiro.x + 0.1, "Player2 continua andando enquanto ataca")
	player2.atacando = false
	player2.tempo_ataque = 0.0
	player2.nome_personagem = "Player2"

	make_hole(arena, Vector2(230, 180))
	await wait_physics()
	player1.global_position = Vector2(170, 180)
	player1.velocidade_controle = Vector2.ZERO
	for _frame in range(60):
		player1.mover(Vector2.RIGHT, 1.0 / 60.0)
	check(player1.global_position.x < 214.0, "buraco bloqueia a caminhada como uma parede")

	var spawn: Node2D = load("res://cenas/objects/respawn/level_spawn.tscn").instantiate()
	spawn.team_spacing = 64.0
	arena.add_child(spawn)
	spawn.global_position = Vector2(300, 180)
	await wait_physics()
	check(player1.obter_ponto_renascimento().distance_to(Vector2(268, 180)) < 0.1, "level spawn posiciona Player1")
	check(player2.obter_ponto_renascimento().distance_to(Vector2(332, 180)) < 0.1, "level spawn posiciona Player2")
	check(player1.global_position.distance_to(Vector2(268, 180)) < 0.1, "level spawn move Player1 para o inicio")
	check(player2.global_position.distance_to(Vector2(332, 180)) < 0.1, "level spawn move Player2 para o inicio")

	var checkpoint: Node2D = load("res://cenas/objects/respawn/checkpoint.tscn").instantiate()
	checkpoint.team_spacing = 48.0
	arena.add_child(checkpoint)
	checkpoint.global_position = Vector2(400, 180)
	checkpoint.get_node("RespawnPoint").global_position = Vector2(440, 220)
	await wait_physics()
	player2.global_position = checkpoint.global_position
	await wait_physics(5)
	check(checkpoint.is_active, "checkpoint detecta um heroi")
	check(player1.obter_ponto_renascimento().distance_to(Vector2(416, 220)) < 0.1, "checkpoint atualiza Player1 no ponto separado do gatilho")
	check(player2.obter_ponto_renascimento().distance_to(Vector2(464, 220)) < 0.1, "checkpoint atualiza Player2 no ponto separado do gatilho")

	make_hole(arena, Vector2(300, 260))
	await wait_physics()
	player2.set_physics_process(true)
	player2.global_position = Vector2(250, 260)
	player2.vida_atual = player2.vida_maxima
	player2.tempo_dano = 0.0
	player2.dash_cooldown_remaining = 0.0
	check(player2.iniciar_dash(Vector2.RIGHT), "dash inicia na direcao do movimento")
	check(not player2.get_collision_mask_value(PhysicsLayers.HOLES), "dash ignora o layer de buracos")
	for _frame in range(30):
		await physics_frame
		if not player2.dashing:
			break
	check(player2.global_position.x > 320.0, "dash atravessa o buraco")
	check(not player2.caindo and not player2.dashing, "dash terminou fora do buraco sem queda")
	check(player2.get_collision_mask_value(PhysicsLayers.HOLES), "colisao com buracos volta ao terminar o dash")

	make_hole(arena, Vector2(360, 300), Vector2(80, 32))
	await wait_physics()
	player2.global_position = Vector2(300, 300)
	player2.vida_atual = player2.vida_maxima
	player2.tempo_dano = 0.0
	player2.dash_cooldown_remaining = 0.0
	player2.definir_ponto_renascimento(Vector2(320, 340))
	player2.definir_ultima_posicao_segura(Vector2(300, 300))
	check(player2.iniciar_dash(Vector2.RIGHT), "segundo dash inicia")
	for _frame in range(30):
		await physics_frame
		if player2.caindo:
			break
	check(player2.caindo, "dash que termina dentro do buraco derruba Player2")
	check(player2.vida_atual == player2.vida_maxima - player2.dano_queda, "queda aplica dano")
	check(not player2.get_collision_mask_value(PhysicsLayers.HOLES), "Player2 permanece sem colisao de buraco durante a queda")
	await create_timer(player2.duracao_queda + 0.2).timeout
	check(not player2.caindo and not player2.esta_morto, "Player2 renasce apos a queda")
	check(player2.global_position.distance_to(Vector2(300, 300)) < 0.1, "Player2 renasce no ultimo piso seguro, nao no checkpoint")
	check(player2.get_collision_mask_value(PhysicsLayers.HOLES), "renascimento restaura a colisao com buracos")
	check(player2.vida_atual == player2.vida_maxima - player2.dano_queda, "dano da queda permanece apos o renascimento")

	if failures.is_empty():
		print("DASH_RESPAWN_OK: %d verificacoes de movimento instantaneo, buracos, dash, queda, level spawn e checkpoint." % total)
		quit(0)
	else:
		print(failures)
		quit(1)
