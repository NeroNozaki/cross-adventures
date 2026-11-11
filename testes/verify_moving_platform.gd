extends SceneTree

var failures: Array[String] = []
var total: int = 0


func _initialize() -> void:
	create_timer(25.0).timeout.connect(func():
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


func retangulo_igual(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) < 0.01 and a.size.distance_to(b.size) < 0.01


func make_hole_map() -> TileMapLayer:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	tile_set.add_physics_layer()
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(1, 0)
	tile_set.set_physics_layer_collision_mask(1, 0)
	var source := TileSetAtlasSource.new()
	var imagem := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	imagem.fill(Color.WHITE)
	source.texture = ImageTexture.create_from_image(imagem)
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, 0)
	var dados: TileData = source.get_tile_data(Vector2i.ZERO, 0)
	dados.add_collision_polygon(1)
	dados.set_collision_polygon_points(1, 0, PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8),
	]))
	var mapa := TileMapLayer.new()
	mapa.tile_set = tile_set
	mapa.scale = Vector2(1.5, 1.5)
	for x in range(-2, 3):
		for y in range(-2, 3):
			mapa.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	return mapa


func run() -> void:
	AudioServer.set_bus_mute(0, true)
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world

	var mapa: TileMapLayer = make_hole_map()
	world.add_child(mapa)
	mapa.position = Vector2.ZERO

	var campo: HoleField = load("res://cenas/objects/hazards/hole_field.tscn").instantiate()
	campo.tile_map_layer = mapa
	campo.scan_physics_layer = 1
	world.add_child(campo)
	await wait_frames(2)
	check(campo.quantidade_celulas() == 25, "HoleField encontra os 25 tiles de buraco")
	check(campo.contem_buraco_bruto(Vector2(0, 0)), "mapa bruto continua marcando buraco coberto")

	var hero: Node2D = load("res://cenas/personagens/player1.tscn").instantiate()
	world.add_child(hero)
	hero.global_position = Vector2(0, 0)
	hero.set_physics_process(false)
	check(hero.get_collision_mask_value(PhysicsLayers.HOLES), "heroi colide com buracos fora da plataforma")

	var scene: PackedScene = load("res://cenas/objects/non-interactable/moving_platform.tscn")
	var platform: Node2D = scene.instantiate()
	platform.channel = &"test.moving_platform"
	platform.move_speed = 400.0
	world.add_child(platform)
	platform.global_position = Vector2(6, 6)
	await wait_frames(6)

	check(platform is NonInteractable, "plataforma herda NonInteractable")
	var partes: Node2D = platform.get_node("Platform")
	var inativo: Marker2D = platform.get_node("InactiveAnchor")
	var ativo: Marker2D = platform.get_node("ActiveAnchor")
	var tilemap: TileMapLayer = platform.get_node("Platform/TileMapLayer")
	check(partes.global_position.distance_to(inativo.global_position) < 0.1, "plataforma comeca no ancora inativo")
	var area: Area2D = platform.obter_area_passageiros()
	check(area != null, "area de passageiros existe")
	check(tilemap.get_node_or_null("HoleSafeArea") == null, "plataforma nao cria area segura de buracos")
	check(not hero.has_method("entrar_plataforma_movel"), "personagem nao conhece plataformas moveis")
	var camada_fisica: int = tilemap.tile_set.get_physics_layer_collision_layer(0)
	check((camada_fisica & (1 << (PhysicsLayers.UNSTABLE_GROUND - 1))) != 0, "plataforma usa a camada de terreno instavel")

	check(campo.obter_pecas_celula(Vector2i(0, 0)).is_empty(), "celula totalmente coberta nao tem colisao de buraco")
	check(not campo.celula_esta_ativa(Vector2i(-2, 0)), "celula parcialmente coberta tambem e desligada inteira")
	check(not campo.celula_esta_ativa(Vector2i(1, 0)), "borda direita coberta desliga a celula inteira")
	var parte_livre: Array[Rect2] = campo.obter_pecas_celula(Vector2i(2, 0))
	check(parte_livre.size() == 1 and retangulo_igual(parte_livre[0], Rect2(48, 0, 24, 24)), "celula fora da plataforma continua inteira")
	check(hero.get_collision_mask_value(PhysicsLayers.HOLES), "heroi mantem a colisao de buracos sobre a plataforma")
	check(not hero.esta_sobre_buraco(), "plataforma cobre o buraco sem desligar a camada do heroi")
	check(hero.esta_sobre_buraco_bruto(), "buraco continua existindo abaixo da plataforma")
	hero.global_position = Vector2(60, 60)
	await wait_frames(6)
	check(hero.esta_sobre_buraco(), "buraco exposto fora da plataforma continua solido")
	check(hero.esta_sobre_buraco_bruto(), "consulta bruta tambem encontra buraco exposto")
	hero.global_position = Vector2(0, 0)
	await wait_frames(6)
	var offset_inicial: Vector2 = hero.global_position - partes.global_position

	var bus := root.get_node("SignalBus")
	bus.publish(&"test.moving_platform", true)
	await wait_frames(3)
	check(platform.esta_em_movimento(), "sinal ligado inicia o movimento")
	await create_timer(0.1).timeout
	var distancia_total: float = inativo.global_position.distance_to(ativo.global_position)
	var distancia_percorrida: float = inativo.global_position.distance_to(partes.global_position)
	check(distancia_percorrida > 1.0 and distancia_percorrida < distancia_total - 1.0, "movimento e suave entre as ancoras")
	await create_timer(0.45).timeout
	check(partes.global_position.distance_to(ativo.global_position) < 0.1, "plataforma chega na ancora ativa")
	check(not platform.esta_em_movimento(), "movimento termina na ancora ativa")
	check(hero.global_position.distance_to(partes.global_position + offset_inicial) < 0.1, "plataforma transporta o passageiro ao ativar")
	check(campo.obter_pecas_celula(Vector2i(0, 0)).size() == 1, "buracos voltam a ficar inteiros quando a plataforma sai")

	bus.publish(&"test.moving_platform", false)
	await create_timer(0.1).timeout
	bus.publish(&"test.moving_platform", true)
	await create_timer(0.5).timeout
	check(partes.global_position.distance_to(ativo.global_position) < 0.1, "inverter no meio do caminho volta para a ancora ativa")

	bus.publish(&"test.moving_platform", false)
	await create_timer(0.6).timeout
	check(partes.global_position.distance_to(inativo.global_position) < 0.1, "sinal desligado volta para a ancora inativa")
	check(hero.global_position.distance_to(partes.global_position + offset_inicial) < 0.1, "passageiro continua sobre a plataforma ao voltar")

	platform.carry_riders = false
	hero.global_position = Vector2(0, 0)
	await wait_frames(3)
	var caiu := [false]
	hero.caiu_no_buraco.connect(func(_personagem): caiu[0] = true)
	bus.publish(&"test.moving_platform", true)
	await create_timer(0.6).timeout
	check(caiu[0], "reexpor o buraco sob o heroi o derruba em vez de empurra-lo")
	bus.publish(&"test.moving_platform", false)
	await create_timer(0.2).timeout

	var iniciada: Node2D = scene.instantiate()
	iniciada.start_activated = true
	world.add_child(iniciada)
	iniciada.global_position = Vector2(1000, 6)
	await wait_frames(5)
	var partes_iniciada: Node2D = iniciada.get_node("Platform")
	var ativa_iniciada: Marker2D = iniciada.get_node("ActiveAnchor")
	check(partes_iniciada.global_position.distance_to(ativa_iniciada.global_position) < 0.1, "start_activated comeca na ancora ativa")

	if failures.is_empty():
		print("MOVING_PLATFORM_OK: %d verificacoes de ancoras, sinal, movimento suave, reversao, celulas desligadas e passageiros." % total)
		quit(0)
	else:
		print(failures)
		quit(1)
