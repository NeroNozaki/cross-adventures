extends Node2D
class_name HoleField

@export var tile_map_layer: TileMapLayer
@export_range(0, 7, 1) var scan_physics_layer: int = 1
@export var solid_collision_layer: int = 64
@export var solid_collision_mask: int = 0

var _cells: Dictionary = {}
var _blockers: Dictionary = {}
var _bodies: Dictionary = {}
var _desativadas: Dictionary = {}


func _ready() -> void:
	add_to_group("hole_fields")
	if tile_map_layer == null:
		push_warning("HoleField sem tile_map_layer; nenhum buraco sera criado.")
	rebuild()


func configure(mapa: TileMapLayer, camada_fisica: int = 1) -> void:
	tile_map_layer = mapa
	scan_physics_layer = camada_fisica
	if is_node_ready():
		rebuild()


func rebuild() -> void:
	_limpar_todos_os_corpos()
	_cells.clear()
	_bodies.clear()
	_desativadas.clear()
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
	for celula in _cells:
		_criar_corpo(celula)
	for celula in _cells:
		_atualizar_celula(celula)


func registrar_bloqueador(id: int, retangulo: Rect2) -> void:
	if retangulo.size.x <= 0.0 or retangulo.size.y <= 0.0:
		remover_bloqueador(id)
		return
	var anterior: Variant = _blockers.get(id)
	_blockers[id] = retangulo
	var afetadas: Dictionary = {}
	if anterior is Rect2:
		_reunir_celulas_em(anterior, afetadas)
	_reunir_celulas_em(retangulo, afetadas)
	_atualizar_celulas(afetadas)


func remover_bloqueador(id: int) -> void:
	if not _blockers.has(id):
		return
	var anterior: Rect2 = _blockers[id]
	_blockers.erase(id)
	var afetadas: Dictionary = {}
	_reunir_celulas_em(anterior, afetadas)
	_atualizar_celulas(afetadas)


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


func celula_esta_ativa(celula: Vector2i) -> bool:
	return _cells.has(celula) and not _desativadas.has(celula)


func obter_pecas_celula(celula: Vector2i) -> Array[Rect2]:
	var pecas: Array[Rect2] = []
	if celula_esta_ativa(celula):
		pecas.append(_cells[celula])
	return pecas


func obter_corpos_celula(celula: Vector2i) -> Array:
	if not _bodies.has(celula):
		return []
	return [_bodies[celula]]


func obter_celulas() -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	for celula in _cells:
		lista.append(celula)
	return lista


func obter_retangulo_celula(celula: Vector2i) -> Rect2:
	return _cells.get(celula, Rect2())


func quantidade_celulas() -> int:
	return _cells.size()


func quantidade_corpos() -> int:
	return _bodies.size()


func _atualizar_celulas(celulas: Dictionary) -> void:
	for celula in celulas:
		_atualizar_celula(celula)


func _atualizar_celula(celula: Vector2i) -> void:
	if not _bodies.has(celula):
		return
	var bloqueada: bool = _celula_esta_bloqueada(celula)
	var estava_bloqueada: bool = _desativadas.has(celula)
	if bloqueada == estava_bloqueada:
		return
	var corpo: StaticBody2D = _bodies[celula]
	if bloqueada:
		corpo.collision_layer = 0
		_desativadas[celula] = true
		return
	_derrubar_herois_na(celula)
	corpo.collision_layer = solid_collision_layer
	_desativadas.erase(celula)


func _celula_esta_bloqueada(celula: Vector2i) -> bool:
	var retangulo: Rect2 = _cells[celula]
	for bloqueador in _blockers.values():
		if retangulo.intersects(bloqueador):
			return true
	return false


func _criar_corpo(celula: Vector2i) -> void:
	var retangulo: Rect2 = _cells[celula]
	var corpo := StaticBody2D.new()
	corpo.name = "Buraco_%d_%d" % [celula.x, celula.y]
	corpo.collision_layer = solid_collision_layer
	corpo.collision_mask = solid_collision_mask
	var forma := RectangleShape2D.new()
	forma.size = retangulo.size
	var colisao := CollisionShape2D.new()
	colisao.shape = forma
	corpo.add_child(colisao)
	add_child(corpo)
	corpo.global_position = retangulo.get_center()
	_bodies[celula] = corpo


func _derrubar_herois_na(celula: Vector2i) -> void:
	if not is_inside_tree():
		return
	var retangulo: Rect2 = _cells[celula]
	for heroi in get_tree().get_nodes_in_group("herois"):
		if not is_instance_valid(heroi) or not heroi.has_method("cair_no_buraco"):
			continue
		if heroi.has_method("pode_cair_em_buraco_reexposto") and not heroi.pode_cair_em_buraco_reexposto():
			continue
		if retangulo.has_point(heroi.global_position):
			heroi.cair_no_buraco()


func _limpar_todos_os_corpos() -> void:
	for corpo in _bodies.values():
		if is_instance_valid(corpo):
			remove_child(corpo)
			corpo.queue_free()
	_bodies.clear()


func _reunir_celulas_em(area: Rect2, destino: Dictionary) -> void:
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return
	if tile_map_layer == null or tile_map_layer.tile_set == null:
		return
	var tamanho: Vector2 = Vector2(tile_map_layer.tile_set.tile_size)
	if tamanho.x <= 0.0 or tamanho.y <= 0.0:
		return
	var inversa: Transform2D = tile_map_layer.global_transform.affine_inverse()
	var cantos: Array[Vector2] = [
		inversa * area.position,
		inversa * Vector2(area.end.x, area.position.y),
		inversa * area.end,
		inversa * Vector2(area.position.x, area.end.y),
	]
	var minimo: Vector2 = cantos[0]
	var maximo: Vector2 = cantos[0]
	for canto in cantos:
		minimo.x = minf(minimo.x, canto.x)
		minimo.y = minf(minimo.y, canto.y)
		maximo.x = maxf(maximo.x, canto.x)
		maximo.y = maxf(maximo.y, canto.y)
	var inicio_x: int = floori(minimo.x / tamanho.x) - 1
	var fim_x: int = floori(maximo.x / tamanho.x) + 1
	var inicio_y: int = floori(minimo.y / tamanho.y) - 1
	var fim_y: int = floori(maximo.y / tamanho.y) + 1
	for x in range(inicio_x, fim_x + 1):
		for y in range(inicio_y, fim_y + 1):
			var celula := Vector2i(x, y)
			if _cells.has(celula) and (_cells[celula] as Rect2).intersects(area):
				destino[celula] = true


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
