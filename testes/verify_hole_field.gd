extends SceneTree

var failures: Array[String] = []
var total: int = 0


func _initialize() -> void:
	create_timer(15.0).timeout.connect(func():
		push_error("Timeout do teste do campo de buracos")
		quit(2)
	)
	call_deferred("run")


func check(ok: bool, text: String) -> void:
	total += 1
	if not ok:
		failures.append(text)
		push_error(text)


func wait_frames(count: int = 3) -> void:
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


func area_total(pecas: Array[Rect2]) -> float:
	var soma := 0.0
	for peca in pecas:
		soma += peca.size.x * peca.size.y
	return soma


func run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world
	var mapa: TileMapLayer = make_hole_map()
	world.add_child(mapa)
	var campo: HoleField = load("res://cenas/objects/hazards/hole_field.tscn").instantiate()
	campo.tile_map_layer = mapa
	campo.scan_physics_layer = 1
	world.add_child(campo)
	await process_frame

	check(campo.quantidade_celulas() == 25, "campo le todas as celulas com poligono de buraco")
	check(campo.celula_esta_ativa(Vector2i(2, 0)), "sem bloqueador a celula fica ativa")
	check(retangulo_igual(campo.obter_retangulo_celula(Vector2i(2, 0)), Rect2(48, 0, 24, 24)), "celula usa o retangulo inteiro do tile")
	var corpos: Array = campo.obter_corpos_celula(Vector2i(2, 0))
	check(corpos.size() == 1 and corpos[0].collision_layer == 64, "corpo unico do buraco usa a camada Buracos")

	campo.registrar_bloqueador(1, Rect2(0, 0, 48, 24))
	check(not campo.celula_esta_ativa(Vector2i(0, 0)), "bloqueador desliga a primeira celula coberta")
	check(not campo.celula_esta_ativa(Vector2i(1, 0)), "bloqueador desliga a segunda celula coberta")
	check(campo.celula_esta_ativa(Vector2i(0, 1)), "celula vizinha permanece ativa")
	check(campo.contem_buraco_bruto(Vector2(12, 12)), "consulta bruta ignora o bloqueador")
	check(campo.contem_buraco_bruto_retangulo(Rect2(12, 12, 2, 2)), "consulta bruta por retangulo tambem funciona")

	campo.registrar_bloqueador(2, Rect2(30, 30, 12, 12))
	check(not campo.celula_esta_ativa(Vector2i(1, 1)), "qualquer sobreposicao desliga a celula inteira")
	check(campo.obter_pecas_celula(Vector2i(1, 1)).is_empty(), "celula desligada nao expoe area solida")
	var corpo_bloqueado: Array = campo.obter_corpos_celula(Vector2i(1, 1))
	check(corpo_bloqueado.size() == 1 and corpo_bloqueado[0].collision_layer == 0, "corpo existente e apenas desligado, sem recriacao")
	check(campo.celula_esta_ativa(Vector2i(2, 1)), "celula fora do bloqueador segue ativa")

	var corpo_reutilizado: Node = corpo_bloqueado[0]
	campo.remover_bloqueador(2)
	check(campo.celula_esta_ativa(Vector2i(1, 1)), "remover bloqueador reativa a celula inteira")
	check(campo.obter_corpos_celula(Vector2i(1, 1))[0] == corpo_reutilizado, "reativar reutiliza o mesmo corpo fisico")
	campo.remover_bloqueador(1)
	check(campo.celula_esta_ativa(Vector2i(0, 0)), "remover o ultimo bloqueador reativa toda a area")

	var area: Node = load("res://cenas/areas/area_3.tscn").instantiate()
	root.add_child(area)
	current_scene = area
	await wait_frames(4)
	var campo_area: HoleField = area.get_node("HoleField") as HoleField
	check(campo_area.tile_map_layer != null, "area_3 resolve a referencia do TileMapLayer no HoleField")
	check(campo_area.quantidade_celulas() >= 600, "area_3 carrega as centenas de buracos reais")
	check(campo_area.quantidade_corpos() == campo_area.quantidade_celulas(), "area_3 cria um corpo fixo por celula de buraco")
	var player1: Node2D = area.get_node("Personagens/Player1")
	player1.set_physics_process(false)
	var celula_exposta := Vector2i(-99999, -99999)
	for celula in campo_area.obter_celulas():
		if campo_area.obter_corpos_celula(celula).size() > 0:
			celula_exposta = celula
			break
	check(celula_exposta.x != -99999, "area_3 tem pelo menos uma celula de buraco exposta")
	if celula_exposta.x != -99999:
		player1.global_position = campo_area.obter_retangulo_celula(celula_exposta).get_center()
		await wait_frames(3)
		check(player1.esta_sobre_buraco(), "heroi real colide com o corpo de buraco criado em area_3")

	if failures.is_empty():
		print("HOLE_FIELD_OK: %d verificacoes de celulas inteiras, desligamento economico e colisao real em area_3." % total)
		quit(0)
	else:
		print(failures)
		quit(1)
