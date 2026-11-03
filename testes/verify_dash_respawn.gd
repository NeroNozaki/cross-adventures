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
	check(InputMap.event_is_action(right_click, "otto_dash"), "clique direito aciona otto_dash")
	check(not InputMap.event_is_action(right_click, "robo_atacar"), "clique direito nao dispara o tiro")
	var left_click := InputEventMouseButton.new()
	left_click.button_index = MOUSE_BUTTON_LEFT
	check(InputMap.event_is_action(left_click, "robo_atacar") and not InputMap.event_is_action(left_click, "otto_dash"), "clique esquerdo continua apenas no tiro")

	var arena: Node2D = load("res://cenas/testes/arena_teste.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await wait_physics()
	var lucas: CharacterBody2D = arena.get_node("Personagens/Guerreiro")
	var otto: CharacterBody2D = arena.get_node("Personagens/Robo")
	var zumbi: CharacterBody2D = arena.get_node("Personagens/Zumbi")
	for actor in [lucas, otto, arena.get_node("Personagens/CavaleiroAzul"), zumbi]:
		actor.set_physics_process(false)
	check(lucas.get_collision_mask_value(PhysicsLayers.HOLES), "herois colidem com buracos")
	check(zumbi.get_collision_mask_value(PhysicsLayers.HOLES), "inimigos colidem com buracos")

	lucas.global_position = Vector2(160, 180)
	lucas.velocidade_controle = Vector2.ZERO
	lucas.mover(Vector2.RIGHT, 1.0 / 60.0)
	check(absf(lucas.velocidade_controle.x - lucas.velocidade) < 0.01, "movimento atinge a velocidade no primeiro quadro")
	lucas.mover(Vector2.ZERO, 1.0 / 60.0)
	check(lucas.velocidade_controle.is_zero_approx() and lucas.velocity.is_zero_approx(), "soltar o comando para imediatamente")

	otto.nome_personagem = "Personagem"
	otto.global_position = Vector2(240, 200)
	otto.atacando = true
	otto.tempo_ataque = 1.0
	var antes_tiro: Vector2 = otto.global_position
	otto.mover(Vector2.RIGHT, 1.0 / 60.0)
	check(otto.global_position.x > antes_tiro.x + 0.1, "Otto continua andando enquanto ataca")
	otto.atacando = false
	otto.tempo_ataque = 0.0
	otto.nome_personagem = "Otto"

	make_hole(arena, Vector2(230, 180))
	await wait_physics()
	lucas.global_position = Vector2(170, 180)
	lucas.velocidade_controle = Vector2.ZERO
	for _frame in range(60):
		lucas.mover(Vector2.RIGHT, 1.0 / 60.0)
	check(lucas.global_position.x < 214.0, "buraco bloqueia a caminhada como uma parede")

	var spawn: Node2D = load("res://cenas/objects/respawn/level_spawn.tscn").instantiate()
	spawn.team_spacing = 64.0
	arena.add_child(spawn)
	spawn.global_position = Vector2(300, 180)
	await wait_physics()
	check(lucas.obter_ponto_renascimento().distance_to(Vector2(268, 180)) < 0.1, "level spawn posiciona Lucas")
	check(otto.obter_ponto_renascimento().distance_to(Vector2(332, 180)) < 0.1, "level spawn posiciona Otto")
	check(lucas.global_position.distance_to(Vector2(268, 180)) < 0.1, "level spawn move Lucas para o inicio")
	check(otto.global_position.distance_to(Vector2(332, 180)) < 0.1, "level spawn move Otto para o inicio")

	var checkpoint: Area2D = load("res://cenas/objects/respawn/checkpoint.tscn").instantiate()
	checkpoint.team_spacing = 48.0
	arena.add_child(checkpoint)
	checkpoint.global_position = Vector2(400, 180)
	await wait_physics()
	otto.global_position = checkpoint.global_position
	await wait_physics(5)
	check(checkpoint.is_active, "checkpoint detecta um heroi")
	check(lucas.obter_ponto_renascimento().distance_to(Vector2(376, 180)) < 0.1, "checkpoint atualiza Lucas")
	check(otto.obter_ponto_renascimento().distance_to(Vector2(424, 180)) < 0.1, "checkpoint atualiza Otto")

	make_hole(arena, Vector2(300, 260))
	await wait_physics()
	otto.set_physics_process(true)
	otto.global_position = Vector2(250, 260)
	otto.vida_atual = otto.vida_maxima
	otto.tempo_dano = 0.0
	otto.dash_cooldown_remaining = 0.0
	check(otto.iniciar_dash(Vector2.RIGHT), "dash inicia na direcao do movimento")
	check(not otto.get_collision_mask_value(PhysicsLayers.HOLES), "dash ignora o layer de buracos")
	for _frame in range(30):
		await physics_frame
		if not otto.dashing:
			break
	check(otto.global_position.x > 320.0, "dash atravessa o buraco")
	check(not otto.caindo and not otto.dashing, "dash terminou fora do buraco sem queda")
	check(otto.get_collision_mask_value(PhysicsLayers.HOLES), "colisao com buracos volta ao terminar o dash")

	make_hole(arena, Vector2(360, 300), Vector2(80, 32))
	await wait_physics()
	otto.global_position = Vector2(300, 300)
	otto.vida_atual = otto.vida_maxima
	otto.tempo_dano = 0.0
	otto.dash_cooldown_remaining = 0.0
	otto.definir_ponto_renascimento(Vector2(320, 340))
	check(otto.iniciar_dash(Vector2.RIGHT), "segundo dash inicia")
	for _frame in range(30):
		await physics_frame
		if otto.caindo:
			break
	check(otto.caindo, "dash que termina dentro do buraco derruba Otto")
	check(otto.vida_atual == otto.vida_maxima - otto.dano_queda, "queda aplica dano")
	check(not otto.get_collision_mask_value(PhysicsLayers.HOLES), "Otto permanece sem colisao de buraco durante a queda")
	await create_timer(otto.duracao_queda + 0.2).timeout
	check(not otto.caindo and not otto.esta_morto, "Otto renasce apos a queda")
	check(otto.global_position.distance_to(Vector2(320, 340)) < 0.1, "Otto renasce no checkpoint")
	check(otto.get_collision_mask_value(PhysicsLayers.HOLES), "renascimento restaura a colisao com buracos")
	check(otto.vida_atual == otto.vida_maxima - otto.dano_queda, "dano da queda permanece apos o renascimento")

	if failures.is_empty():
		print("DASH_RESPAWN_OK: %d verificacoes de movimento instantaneo, buracos, dash, queda, level spawn e checkpoint." % total)
		quit(0)
	else:
		print(failures)
		quit(1)
