extends SceneTree

var failures: Array[String] = []
var total: int = 0


func _initialize() -> void:
	create_timer(20.0).timeout.connect(func():
		push_error("Timeout do teste da plataforma movel")
		quit(2)
	)
	call_deferred("run")


func check(ok: bool, text: String) -> void:
	total += 1
	if not ok:
		failures.append(text)
		push_error(text)


func wait_frames(count: int = 4) -> void:
	for _i in range(count):
		await physics_frame
	await process_frame


func run() -> void:
	AudioServer.set_bus_mute(0, true)
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world

	var hero: Node2D = load("res://cenas/personagens/guerreiro.tscn").instantiate()
	world.add_child(hero)
	hero.global_position = Vector2.ZERO
	hero.set_physics_process(false)

	var scene: PackedScene = load("res://cenas/objects/non-interactable/moving_platform.tscn")
	var platform: Node2D = scene.instantiate()
	platform.channel = &"test.moving_platform"
	platform.move_speed = 400.0
	world.add_child(platform)
	platform.global_position = Vector2(200, 200)
	await wait_frames(5)

	check(platform is NonInteractable, "plataforma herda NonInteractable")
	var partes: Node2D = platform.get_node("Platform")
	var inativo: Marker2D = platform.get_node("InactiveAnchor")
	var ativo: Marker2D = platform.get_node("ActiveAnchor")
	var tilemap: TileMapLayer = platform.get_node("Platform/TileMapLayer")
	check(partes.global_position.distance_to(inativo.global_position) < 0.1, "plataforma comeca no ancora inativo")
	check(is_equal_approx(inativo.global_position.x, 200.0), "ancora inativa usa a posicao do no")
	var camada_fisica: int = tilemap.tile_set.get_physics_layer_collision_layer(0)
	check((camada_fisica & (1 << (PhysicsLayers.UNSTABLE_GROUND - 1))) != 0, "plataforma usa a camada de terreno instavel")
	var area: Area2D = platform.obter_area_passageiros()
	check(area != null, "area de passageiros existe")
	hero.global_position = area.global_position
	await wait_frames(5)
	var offset_inicial: Vector2 = hero.global_position - partes.global_position

	var bus := root.get_node("SignalBus")
	bus.publish(&"test.moving_platform", true)
	await wait_frames(3)
	check(platform.esta_em_movimento(), "sinal ligado inicia o movimento")
	await create_timer(0.1).timeout
	check(partes.global_position.x > inativo.global_position.x + 1.0 and partes.global_position.x < ativo.global_position.x - 1.0, "movimento e suave entre as ancoras")
	await create_timer(0.45).timeout
	check(partes.global_position.distance_to(ativo.global_position) < 0.1, "plataforma chega na ancora ativa")
	check(not platform.esta_em_movimento(), "movimento termina na ancora ativa")
	check(hero.global_position.distance_to(partes.global_position + offset_inicial) < 0.1, "plataforma transporta o passageiro ao ativar")

	bus.publish(&"test.moving_platform", false)
	await create_timer(0.1).timeout
	bus.publish(&"test.moving_platform", true)
	await create_timer(0.5).timeout
	check(partes.global_position.distance_to(ativo.global_position) < 0.1, "inverter no meio do caminho volta para a ancora ativa")

	bus.publish(&"test.moving_platform", false)
	await create_timer(0.6).timeout
	check(partes.global_position.distance_to(inativo.global_position) < 0.1, "sinal desligado volta para a ancora inativa")
	check(hero.global_position.distance_to(partes.global_position + offset_inicial) < 0.1, "passageiro continua sobre a plataforma ao voltar")

	var iniciada: Node2D = scene.instantiate()
	iniciada.start_activated = true
	world.add_child(iniciada)
	iniciada.global_position = Vector2(500, 200)
	await wait_frames(5)
	var partes_iniciada: Node2D = iniciada.get_node("Platform")
	var ativa_iniciada: Marker2D = iniciada.get_node("ActiveAnchor")
	check(partes_iniciada.global_position.distance_to(ativa_iniciada.global_position) < 0.1, "start_activated comeca na ancora ativa")

	if failures.is_empty():
		print("MOVING_PLATFORM_OK: %d verificacoes de ancoras, sinal, movimento suave, reversao e passageiros." % total)
		quit(0)
	else:
		print(failures)
		quit(1)
