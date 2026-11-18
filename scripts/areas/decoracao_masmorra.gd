extends Node2D
## Camada de acabamento da campanha. As coordenadas apontam para a alvenaria das cenas.
const TALHA := "res://assets/mapa/CRAFTPIX_DUNGEON/talha_masmorra.svg"
const OBJETOS = preload("res://assets/mapa/CRAFTPIX_DUNGEON/Objects.png")
const POSICOES = preload("res://recursos/decoracao_areas.gd")
const FACES := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const ARANDELA := Rect2i(32, 0, 16, 24)
const SENTINELA := Rect2i(0, 0, 32, 40)
const MUSGO := Rect2i(104, 0, 24, 16)
const MEDALHAO := Rect2i(36, 40, 24, 24)
const URNA := Rect2i(208, 80, 16, 16)
var terreno: TileMapLayer
var paredes: TileMapLayer
var campo: HoleField
var sala: Node2D
var atlas: Texture2D
var objetos: Node
var arandelas: Array[Vector2] = []
var sentinelas: Array[Vector2] = []
var musgos: Array[Transform2D] = []
var juntas: Array[Vector2] = []
var fissuras: Array[Vector2] = []
var placas_gastas: Array[Rect2] = []
var bases_de_parede: Array[Rect2] = []
var sombras: Array[Rect2] = []
var vaos: Array[Rect2] = []
var cor_pedra: Color
var cor_musgo: Color
var _regioes := {}

func _ponto(celula: Vector2i) -> Vector2:
	return to_local(terreno.to_global(terreno.map_to_local(celula))).round()

func _parede(celula: Vector2i) -> bool:
	var base := terreno.get_cell_tile_data(celula)
	var ladrilho := paredes.get_cell_tile_data(celula) if paredes else null
	return (base != null and base.get_collision_polygons_count(0) > 0) or (
		ladrilho != null and ladrilho.get_collision_polygons_count(0) > 0)

func _piso(celula: Vector2i) -> bool:
	var base := terreno.get_cell_tile_data(celula)
	return base != null and not _parede(celula) and base.get_collision_polygons_count(campo.scan_physics_layer) == 0

func _livre(posicao: Vector2, distancia: float) -> bool:
	for parte in objetos.get_children():
		if parte is Node2D and to_local(parte.global_position).distance_squared_to(posicao) < distancia * distancia:
			return false
	return true

func montar(raiz: Node2D, buracos: HoleField, mecanismos: Node, fase: int) -> void:
	sala = raiz
	campo = buracos
	terreno = campo.tile_map_layer
	paredes = sala.get_node_or_null("Object map layer") as TileMapLayer
	objetos = mecanismos
	atlas = load(TALHA)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_as_relative = false
	z_index = terreno.z_index + 1
	cor_pedra = [Color("a6aaa0"), Color("8caab0"), Color("b8a78d")][fase]
	cor_musgo = [Color("9ca075"), Color("8faea1"), Color("c1ad83")][fase]
	var celulas := terreno.get_used_cells()
	celulas.sort()
	for celula in celulas:
		_cobrir_piso(celula, fase)
	for marcador in POSICOES.CANTOS_COM_URNAS[fase]:
		var celula := Vector2i(marcador.x, marcador.y)
		var lado: Vector2i = FACES[marcador.z]
		if _piso(celula) and _parede(celula + lado) and _livre(_ponto(celula), 26):
			_ornamento(URNA, _ponto(celula) + Vector2(lado) * 5, cor_pedra, true, OBJETOS)
	for marcador in POSICOES.NICHOS[fase]:
		var apoio := Vector2i(marcador.x, marcador.y)
		var lado: Vector2i = FACES[marcador.z]
		if _parede(apoio) and _piso(apoio + lado) and _livre(_ponto(apoio), 27):
			var posicao := _ponto(apoio)
			_ornamento(SENTINELA, posicao + Vector2(lado) * 6 + Vector2(0, 6), cor_pedra.lightened(0.33), true)
			sentinelas.append(posicao)
	for marcador in POSICOES.ARANDELAS[fase]:
		var apoio := Vector2i(marcador.x, marcador.y)
		var lado: Vector2i = FACES[marcador.z]
		var posicao := _ponto(apoio)
		if _parede(apoio) and _piso(apoio + lado) and _livre(posicao, 12) and not posicao in sentinelas:
			var base := posicao + Vector2(lado) * 6
			_ornamento(ARANDELA, base + Vector2(0, 8), Color.WHITE, true)
			arandelas.append(base - Vector2(0, 13))
	for celula: Vector2i in POSICOES.SELOS[fase]:
		if _piso(celula) and _livre(_ponto(celula), 19):
			_ornamento(MEDALHAO, _ponto(celula), cor_pedra.lightened(0.18), false)

func _textura(regiao: Rect2i, fonte: Texture2D) -> AtlasTexture:
	if _regioes.has(regiao):
		return _regioes[regiao]
	var recorte := AtlasTexture.new()
	recorte.atlas = fonte
	recorte.region = Rect2(regiao)
	recorte.filter_clip = true
	_regioes[regiao] = recorte
	return recorte

func _ornamento(regiao: Rect2i, posicao: Vector2, tinta: Color, plantar: bool, fonte: Texture2D = null) -> void:
	var imagem := Sprite2D.new()
	imagem.texture = _textura(regiao, atlas if fonte == null else fonte)
	imagem.self_modulate = tinta
	imagem.position = posicao
	if plantar:
		imagem.offset.y = -regiao.size.y * 0.5
		imagem.z_index = 2
	add_child(imagem)

func _cobrir_piso(celula: Vector2i, fase: int) -> void:
	var tamanho := Vector2(terreno.tile_set.tile_size) * terreno.scale
	var centro := _ponto(celula)
	var canto := (centro - tamanho * 0.5).round()
	if not _piso(celula):
		if _parede(celula):
			return
		var dado := terreno.get_cell_tile_data(celula)
		if dado and dado.get_collision_polygons_count(campo.scan_physics_layer) > 0 and _piso(celula + Vector2i.UP):
			vaos.append(Rect2(canto, Vector2(tamanho.x, 13)))
		return
	var semente := hash(Vector3i(celula.x, celula.y, fase))
	var zona := hash(Vector2i(floori(celula.x / 4.0), floori(celula.y / 3.0)))
	if posmod(zona, 5) < 2 and posmod(semente, 7) < 3:
		var posicao := canto + Vector2(2 + posmod(semente, 5), 2 + posmod(semente, 4))
		placas_gastas.append(Rect2(posicao, Vector2(10 + posmod(semente, 5), 7 + posmod(semente, 3))))
	var perto := false
	for lado in FACES:
		if not _parede(celula + lado):
			continue
		perto = true
		var margem := Vector2(lado) * (tamanho / 2 - Vector2(3, 3))
		var tamanho_sombra := Vector2(6, tamanho.y) if lado.x != 0 else Vector2(tamanho.x, 6)
		sombras.append(Rect2((centro + margem - tamanho_sombra / 2).round(), tamanho_sombra))
		if lado == Vector2i.UP:
			bases_de_parede.append(Rect2(canto + Vector2(0, 1), Vector2(tamanho.x, 1)))
		if posmod(semente + lado.x * 13 + lado.y * 8, 11) < (4 if fase == 1 else 3):
			var rotacao := Vector2.DOWN.angle_to(-Vector2(lado))
			musgos.append(Transform2D(rotacao, (centro + margem * 0.8).round()))
	if posmod(semente, 9) < 3:
		juntas.append(centro + Vector2(posmod(semente, 8) - 4, posmod(semente, 9) - 4))
	if perto and posmod(semente, 13) == 0:
		fissuras.append(centro + Vector2(posmod(semente, 5) - 2, posmod(semente, 7) - 3))

func _draw() -> void:
	var sombra := Color(0.018, 0.024, 0.058, 0.22)
	for i in placas_gastas.size():
		var placa := placas_gastas[i]
		draw_rect(placa, Color(cor_pedra, 0.055) if i % 2 == 0 else Color(0.15, 0.19, 0.25, 0.12))
		draw_rect(Rect2(placa.position + Vector2(2, 0), Vector2(placa.size.x - 3, 1)), Color(cor_pedra, 0.12))
	for base in bases_de_parede:
		draw_rect(base, Color(cor_pedra, 0.20))
	for borda in sombras:
		draw_rect(borda, sombra)
		draw_rect(borda.grow(-2), Color(0.025, 0.03, 0.06, 0.12))
	for vao in vaos:
		draw_rect(vao, Color(0.025, 0.032, 0.07, 0.29))
		draw_rect(Rect2(vao.position, Vector2(vao.size.x, 4)), Color(0.033, 0.041, 0.08, 0.56))
		draw_rect(Rect2(vao.position, Vector2(vao.size.x, 1)), Color(cor_pedra, 0.28))
	for i in juntas.size():
		var ponto := juntas[i]
		var largura := 6 + (i % 4) * 3
		draw_rect(Rect2(ponto, Vector2(largura, 1)), Color(0.10, 0.14, 0.20, 0.30))
		draw_rect(Rect2(ponto + Vector2(2, 1), Vector2(largura - 4, 1)), Color(cor_pedra, 0.13))
		if i % 3 == 0:
			draw_rect(Rect2(ponto + Vector2(largura - 1, -3), Vector2(1, 3)), Color(0.10, 0.14, 0.20, 0.24))
	var rachadura := PackedVector2Array([Vector2(-6, -4), Vector2(-3, -4), Vector2(-2, -2),
		Vector2(1, -2), Vector2(1, 1), Vector2(4, 2), Vector2(5, 5)])
	for i in fissuras.size():
		draw_set_transform(fissuras[i], float(i % 4) * PI / 2.0)
		draw_polyline(rachadura, Color(0.08, 0.11, 0.17, 0.62), 1)
		draw_line(Vector2(1, 0), Vector2(7, -2), Color(0.08, 0.11, 0.17, 0.56), 1)
		draw_line(Vector2(2, -1), Vector2(6, -2), Color(cor_pedra, 0.27), 1)
	if atlas:
		var musgo := _textura(MUSGO, atlas)
		for transformacao in musgos:
			draw_set_transform_matrix(transformacao)
			draw_texture(musgo, Vector2(-12, -8), Color(cor_musgo, 0.79))
	draw_set_transform(Vector2.ZERO)
