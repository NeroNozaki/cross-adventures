extends SceneTree

var failures: Array[String] = []
var total: int = 0


func _initialize() -> void:
	create_timer(20.0).timeout.connect(func():
		push_error("Timeout do teste de regras de renascimento")
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


func make_hero(scene_path: String, parent: Node, position: Vector2) -> Node2D:
	var hero: Node2D = load(scene_path).instantiate()
	parent.add_child(hero)
	hero.global_position = position
	hero.set_physics_process(false)
	return hero


func make_checkpoint(parent: Node, position: Vector2, respawn_position: Vector2) -> Node2D:
	var checkpoint: Node2D = load("res://cenas/objects/respawn/checkpoint.tscn").instantiate()
	checkpoint.set("team_spacing", 0.0)
	parent.add_child(checkpoint)
	checkpoint.global_position = position
	checkpoint.get_node("RespawnPoint").global_position = respawn_position
	return checkpoint


func make_unstable_ground(parent: Node, position: Vector2, size: Vector2) -> StaticBody2D:
	var ground := StaticBody2D.new()
	ground.collision_layer = 1 << (PhysicsLayers.UNSTABLE_GROUND - 1)
	ground.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	ground.add_child(shape)
	parent.add_child(ground)
	ground.global_position = position
	return ground


func run() -> void:
	AudioServer.set_bus_mute(0, true)
	check(PhysicsLayers.UNSTABLE_GROUND == 8, "camada de terreno instavel usa o indice 8")
	check(ProjectSettings.get_setting("layer_names/2d_physics/layer_8") == "TerrenoInstavel", "camada de terreno instavel tem nome no projeto")

	var world := Node2D.new()
	root.add_child(world)
	current_scene = world

	var lucas := make_hero("res://cenas/personagens/guerreiro.tscn", world, Vector2.ZERO)
	var otto := make_hero("res://cenas/personagens/robo.tscn", world, Vector2.ZERO)
	var spawn: Node2D = load("res://cenas/objects/respawn/level_spawn.tscn").instantiate()
	spawn.set("team_spacing", 0.0)
	world.add_child(spawn)
	spawn.global_position = Vector2(100, 100)
	await wait_physics(5)
	check(lucas.global_position.distance_to(Vector2(100, 100)) < 0.1, "level spawn posiciona Lucas")
	check(otto.global_position.distance_to(Vector2(100, 100)) < 0.1, "level spawn posiciona Otto")

	var ponto_a := Vector2(340, 240)
	var ponto_b := Vector2(540, 240)
	var checkpoint_a := make_checkpoint(world, Vector2(300, 200), ponto_a)
	var checkpoint_b := make_checkpoint(world, Vector2(500, 200), ponto_b)

	otto.global_position = checkpoint_a.global_position
	await wait_physics(5)
	check(checkpoint_a.is_active, "primeiro checkpoint ativa")
	check(Checkpoint.checkpoint_ativo == checkpoint_a, "primeiro checkpoint vira o ativo")
	check(lucas.obter_ponto_renascimento().distance_to(ponto_a) < 0.1, "primeiro checkpoint atualiza Lucas")
	check(otto.obter_ponto_renascimento().distance_to(ponto_a) < 0.1, "primeiro checkpoint atualiza Otto")

	lucas.global_position = checkpoint_b.global_position
	await wait_physics(5)
	check(checkpoint_b.is_active, "segundo checkpoint ativa")
	check(not checkpoint_a.is_active, "segundo checkpoint desativa o primeiro")
	check(Checkpoint.checkpoint_ativo == checkpoint_b, "segundo checkpoint vira o unico ativo")
	check(lucas.obter_ponto_renascimento().distance_to(ponto_b) < 0.1, "segundo checkpoint atualiza Lucas")
	check(otto.obter_ponto_renascimento().distance_to(ponto_b) < 0.1, "segundo checkpoint atualiza Otto")

	otto.global_position = Vector2.ZERO
	await wait_physics(3)
	otto.global_position = checkpoint_a.global_position
	await wait_physics(5)
	check(checkpoint_a.is_active, "checkpoint antigo pode ser reativado")
	check(not checkpoint_b.is_active, "reativar o primeiro desativa o segundo")
	check(Checkpoint.checkpoint_ativo == checkpoint_a, "ultimo checkpoint acionado fica ativo")
	check(lucas.obter_ponto_renascimento().distance_to(ponto_a) < 0.1, "reativacao volta o ponto de Lucas")
	check(otto.obter_ponto_renascimento().distance_to(ponto_a) < 0.1, "reativacao volta o ponto de Otto")

	lucas.vida_atual = 1
	lucas.invulnerabilidade.stop()
	lucas.receber_dano(9999, lucas.global_position + Vector2.LEFT)
	check(lucas.esta_morto, "dano letal derruba Lucas")
	await create_timer(lucas.tempo_renascimento_morte + 0.25).timeout
	check(not lucas.esta_morto, "Lucas renasce sozinho apos morrer")
	check(lucas.vida_atual == lucas.vida_maxima, "renascimento por morte restaura toda a vida")
	check(lucas.global_position.distance_to(ponto_a) < 0.1, "renascimento por morte usa o checkpoint mais recente")

	var unstable_position := Vector2(800, 400)
	make_unstable_ground(world, unstable_position, Vector2(96, 96))
	await wait_physics(2)
	check(otto.esta_sobre_terreno_instavel(unstable_position), "consulta detecta terreno instavel")
	check(not otto.esta_sobre_terreno_instavel(Vector2(100, 100)), "consulta aceita piso estavel")

	otto.definir_ponto_renascimento(unstable_position)
	otto.definir_ultima_posicao_segura(Vector2(100, 100))
	otto.definir_ponto_seguro_inicial(Vector2(100, 100))
	otto.respawn(true)
	await wait_physics()
	check(otto.global_position.distance_to(Vector2(100, 100)) < 0.1, "respawn recusa terreno instavel e usa o ultimo piso seguro")

	otto.global_position = unstable_position
	otto.ultima_posicao_segura = Vector2(100, 100)
	otto.mover(Vector2.RIGHT, 1.0 / 60.0)
	check(otto.ultima_posicao_segura.distance_to(Vector2(100, 100)) < 0.1, "andar sobre terreno instavel nao grava piso seguro")

	otto.definir_ponto_renascimento(unstable_position)
	otto.definir_ultima_posicao_segura(unstable_position)
	otto.definir_ponto_seguro_inicial(Vector2(50, 50))
	otto.respawn(true)
	await wait_physics()
	check(otto.global_position.distance_to(Vector2(50, 50)) < 0.1, "respawn cai para o ponto inicial se o ultimo piso tambem for instavel")

	if failures.is_empty():
		print("RESPAWN_RULES_OK: %d verificacoes de checkpoints exclusivos, morte, piso seguro e terreno instavel." % total)
		quit(0)
	else:
		print(failures)
		quit(1)
