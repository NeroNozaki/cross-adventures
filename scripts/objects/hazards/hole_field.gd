extends Node2D
class_name HoleField

@export var tile_map_layer: TileMapLayer
@export_range(0, 7, 1) var scan_physics_layer: int = 1
@export var solid_collision_layer: int = 64
@export var solid_collision_mask: int = 0

var _cells: Dictionary = {}
var _blockers: Dictionary = {}
var _bodies: Dictionary = {}


func _ready() -> void:
	add_to_group("hole_fields")
	rebuild()


func configure(mapa: TileMapLayer, camada_fisica: int = 1) -> void:
	tile_map_layer = mapa
	scan_physics_layer = camada_fisica
	if is_node_ready():
		rebuild()


func rebuild() -> void:
	_limpar_todos_os_corpos()
	_cells.clear()
	if tile_map_layer == null or tile_map_layer.tile_set == null:
		return
	var tamanho: Vector2 = Vector2(tile_map_layer.tile_set.tile_size)
	for celula in tile_map_layer.get_used_cells():
		var dados: TileData = tile_map_layer.get_cell_tile_data(celula)
		if dados == null or dados.get_collision_polygons_count(scan_physics_layer) <= 0:
			continue
		var limites: Rect2 = _limites_dos_poligonos(dados)
		if limites.size.x <= 0.0 or limites.size.y <= 0.0:
			continue
		var metade: Vector2 = tamanho * 0.5
		var retangulo_local := Rect2(Vector2(celula) * tamanho + metade + limites.position, limites.size)
		_cells[celula] = _retangulo_para_mundo(retangulo_local)
	_reconstruir_todas_as_celulas()


func registrar_bloqueador(id: int, retangulo: Rect2) -> void:
	if retangulo.size.x <= 0.0 or retangulo.size.y <= 0.0:
		remover_bloqueador(id)
		return
	var anterior: Variant = _blockers.get(id)
	_blockers[id] = retangulo
	var afetadas: Dictionary = {}
	_reunir_celulas_em(anterior, afetadas)
	_reunir_celulas_em(retangulo, afetadas)
	_reconstruir_celulas(afetadas)


func remover_bloqueador(id: int) -> void:
	if not _blockers.has(id):
		return
	var anterior: Rect2 = _blockers[id]
	_blockers.erase(id)
	var afetadas: Dictionary = {}
	_reunir_celulas_em(anterior, afetadas)
	_reconstruir_celulas(afetadas)


func contem_buraco_bruto(ponto: Vector2) -> bool:
	for retangulo in _cells.values():
		if (retangulo as Rect2).has_point(ponto):
			return true
	return false


func contem_buraco_bruto_retangulo(retangulo: Rect2) -> bool:
	for celula in _cells.values():
		if (celula as Rect2).intersects(retangulo):
			return true
	return false


func obter_pecas_celula(celula: Vector2i) -> Array[Rect2]:
	var pecas: Array[Rect2] = []
	if not _cells.has(celula):
		return pecas
	pecas.append(_cells[celula])
	for bloqueador in _blockers.values():
		var restantes: Array[Rect2] = []
		for peca in pecas:
			restantes.append_array(_subtrair_retangulo(peca, bloqueador))
		pecas = restantes
		if pecas.is_empty():
			break
	return pecas


func obter_corpos_celula(celula: Vector2i) -> Array:
	return _bodies.get(celula, [])


func quantidade_celulas() -> int:
	return _cells.size()


func _reconstruir_todas_as_celulas() -> void:
	for celula in _cells:
		_reconstruir_celula(celula)


func _reconstruir_celulas(celulas: Dictionary) -> void:
	if celulas.is_empty():
		return
	for celula in celulas:
		_reconstruir_celula(celula)


func _reconstruir_celula(celula: Vector2i) -> void:
	var pecas: Array[Rect2] = obter_pecas_celula(celula)
	_derrubar_herois_em(pecas)
	_limpar_corpos_da_celula(celula)
	var corpos: Array = []
	for indice in range(pecas.size()):
		corpos.append(_criar_corpo(pecas[indice], celula, indice))
	if corpos.is_empty():
		_bodies.erase(celula)
	else:
		_bodies[celula] = corpos


func _criar_corpo(peca: Rect2, celula: Vector2i, indice: int) -> StaticBody2D:
	var corpo := StaticBody2D.new()
	corpo.name = "Buraco_%d_%d_%d" % [celula.x, celula.y, indice]
	corpo.collision_layer = solid_collision_layer
	corpo.collision_mask = solid_collision_mask
	var forma := RectangleShape2D.new()
	forma.size = peca.size
	var colisao := CollisionShape2D.new()
	colisao.shape = forma
	corpo.add_child(colisao)
	add_child(corpo)
	corpo.global_position = peca.get_center()
	return corpo


func _limpar_corpos_da_celula(celula: Vector2i) -> void:
	if not _bodies.has(celula):
		return
	for corpo in _bodies[celula]:
		if is_instance_valid(corpo):
			remove_child(corpo)
			corpo.queue_free()
	_bodies.erase(celula)


func _limpar_todos_os_corpos() -> void:
	for celula in _bodies.keys():
		_limpar_corpos_da_celula(celula)
	_bodies.clear()


func _derrubar_herois_em(pecas: Array[Rect2]) -> void:
	if pecas.is_empty() or not is_inside_tree():
		return
	for heroi in get_tree().get_nodes_in_group("herois"):
		if not is_instance_valid(heroi) or not heroi.has_method("cair_no_buraco"):
			continue
		if heroi.has_method("pode_cair_em_buraco_reexposto") and not heroi.pode_cair_em_buraco_reexposto():
			continue
		for peca in pecas:
			if peca.has_point(heroi.global_position):
				heroi.cair_no_buraco()
				break


func _reunir_celulas_em(retangulo: Variant, destino: Dictionary) -> void:
	if not retangulo is Rect2:
		return
	var area: Rect2 = retangulo
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return
	for celula in _cells:
		if (_cells[celula] as Rect2).intersects(area):
			destino[celula] = true


func _subtrair_retangulo(base: Rect2, corte: Rect2) -> Array[Rect2]:
	var intersecao: Rect2 = base.intersection(corte)
	if intersecao.size.x <= 0.001 or intersecao.size.y <= 0.001:
		return [base]
	var resultado: Array[Rect2] = []
	var inicio: Vector2 = base.position
	var fim: Vector2 = base.end
	var topo := Rect2(inicio, Vector2(base.size.x, intersecao.position.y - inicio.y))
	var baixo := Rect2(Vector2(inicio.x, intersecao.end.y), Vector2(base.size.x, fim.y - intersecao.end.y))
	var meio_y: float = intersecao.position.y
	var meio_altura: float = intersecao.size.y
	var esquerda := Rect2(Vector2(inicio.x, meio_y), Vector2(intersecao.position.x - inicio.x, meio_altura))
	var direita := Rect2(Vector2(intersecao.end.x, meio_y), Vector2(fim.x - intersecao.end.x, meio_altura))
	for peca in [topo, baixo, esquerda, direita]:
		if peca.size.x > 0.001 and peca.size.y > 0.001:
			resultado.append(peca)
	return resultado


func _limites_dos_poligonos(dados: TileData) -> Rect2:
	var pontos: PackedVector2Array = PackedVector2Array()
	for indice in range(dados.get_collision_polygons_count(scan_physics_layer)):
		pontos.append_array(dados.get_collision_polygon_points(scan_physics_layer, indice))
	if pontos.is_empty():
		return Rect2()
	var minimo: Vector2 = pontos[0]
	var maximo: Vector2 = pontos[0]
	for ponto in pontos:
		minimo.x = minf(minimo.x, ponto.x)
		minimo.y = minf(minimo.y, ponto.y)
		maximo.x = maxf(maximo.x, ponto.x)
		maximo.y = maxf(maximo.y, ponto.y)
	return Rect2(minimo, maximo - minimo)


func _retangulo_para_mundo(retangulo: Rect2) -> Rect2:
	var transformacao: Transform2D = tile_map_layer.global_transform
	var cantos: Array[Vector2] = [
		transformacao * retangulo.position,
		transformacao * Vector2(retangulo.end.x, retangulo.position.y),
		transformacao * retangulo.end,
		transformacao * Vector2(retangulo.position.x, retangulo.end.y),
	]
	var minimo: Vector2 = cantos[0]
	var maximo: Vector2 = cantos[0]
	for canto in cantos:
		minimo.x = minf(minimo.x, canto.x)
		minimo.y = minf(minimo.y, canto.y)
		maximo.x = maxf(maximo.x, canto.x)
		maximo.y = maxf(maximo.y, canto.y)
	return Rect2(minimo, maximo - minimo)
