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
	world.add_child(campo)
	campo.configure(mapa, 1)
	await process_frame

	check(campo.quantidade_celulas() == 25, "campo le todas as celulas com poligono de buraco")
	check(campo.obter_pecas_celula(Vector2i(2, 0)).size() == 1, "sem bloqueador a celula inteira fica solida")
	var corpos: Array = campo.obter_corpos_celula(Vector2i(2, 0))
	check(corpos.size() == 1 and corpos[0].collision_layer == 64, "corpo do buraco usa a camada Buracos")

	campo.registrar_bloqueador(1, Rect2(0, 0, 48, 24))
	check(campo.obter_pecas_celula(Vector2i(0, 0)).is_empty(), "bloqueador inteiro remove a celula coberta")
	check(campo.obter_pecas_celula(Vector2i(1, 0)).is_empty(), "bloqueador inteiro remove a segunda celula coberta")
	check(retangulo_igual(campo.obter_pecas_celula(Vector2i(0, 1))[0], Rect2(0, 24, 24, 24)), "celula vizinha permanece inteira")
	check(campo.contem_buraco_bruto(Vector2(12, 12)), "consulta bruta ignora o bloqueador")
	check(campo.contem_buraco_bruto_retangulo(Rect2(12, 12, 2, 2)), "consulta bruta por retangulo tambem funciona")

	campo.registrar_bloqueador(2, Rect2(30, 30, 12, 12))
	var partes: Array[Rect2] = campo.obter_pecas_celula(Vector2i(1, 1))
	check(partes.size() == 4, "corte interno divide a celula em quatro fragmentos")
	check(is_equal_approx(area_total(partes), 576.0 - 144.0), "fragmentos preservam exatamente a area exposta")
	var tem_topo := false
	var tem_fundo := false
	var tem_esquerda := false
	var tem_direita := false
	for parte in partes:
		tem_topo = tem_topo or retangulo_igual(parte, Rect2(24, 24, 24, 6))
		tem_fundo = tem_fundo or retangulo_igual(parte, Rect2(24, 42, 24, 6))
		tem_esquerda = tem_esquerda or retangulo_igual(parte, Rect2(24, 30, 6, 12))
		tem_direita = tem_direita or retangulo_igual(parte, Rect2(42, 30, 6, 12))
	check(tem_topo and tem_fundo and tem_esquerda and tem_direita, "fragmentos ficam exatamente fora do retangulo bloqueado")
	check(campo.obter_corpos_celula(Vector2i(1, 1)).size() == 4, "um corpo fisico e criado por fragmento")

	campo.remover_bloqueador(2)
	check(campo.obter_pecas_celula(Vector2i(1, 1)).size() == 1, "remover bloqueador restaura a celula inteira")
	campo.remover_bloqueador(1)
	check(campo.obter_pecas_celula(Vector2i(0, 0)).size() == 1, "remover o ultimo bloqueador restaura toda a area")

	if failures.is_empty():
		print("HOLE_FIELD_OK: %d verificacoes de leitura, recorte exato e restauracao." % total)
		quit(0)
	else:
		print(failures)
		quit(1)
