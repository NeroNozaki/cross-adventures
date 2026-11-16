extends Node2D
## Acabamento aditivo: não move mapas, mecanismos ou formas de colisão.
const MAPAS = preload("res://recursos/mapas_puzzle.gd")
const FOGO = preload("res://assets/mapa/CRAFTPIX_DUNGEON/fire_animation.png")
const AGUA = preload("res://recursos/agua_masmorra.gdshader")
const VINHETA = preload("res://recursos/vinheta_masmorra.gdshader")
var sala: Node2D
var tempo := 0.0
var aleatorio := RandomNumberGenerator.new()
var luzes: Array[Dictionary] = []
var cristais: Array[Dictionary] = []
var herois: Array[Dictionary] = []
var particulas: Array[Dictionary] = []
var ondas: Array[Dictionary] = []
var faiscas_em := 0.0
var textura_luz: GradientTexture2D
var vinheta: ColorRect

func _ready() -> void:
	sala = get_parent()
	z_index = 4
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	aleatorio.randomize()
	textura_luz = GradientTexture2D.new()
	textura_luz.width = 96
	textura_luz.height = 96
	textura_luz.fill = GradientTexture2D.FILL_RADIAL
	textura_luz.fill_from = Vector2(0.5, 0.5)
	textura_luz.fill_to = Vector2(1.0, 0.5)
	textura_luz.gradient = Gradient.new()
	textura_luz.gradient.set_color(0, Color(1, 1, 1, 0.8))
	textura_luz.gradient.set_color(1, Color(1, 1, 1, 0))
	var ambiente := CanvasModulate.new()
	ambiente.name = "LuzAmbiente"
	ambiente.color = Color(0.76, 0.80, 0.88)
	add_child(ambiente)
	var camada := CanvasLayer.new()
	camada.layer = 8
	add_child(camada)
	vinheta = ColorRect.new()
	vinheta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vinheta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var acabamento := ShaderMaterial.new()
	acabamento.shader = VINHETA
	vinheta.material = acabamento
	camada.add_child(vinheta)
	_preparar_sala()
	for heroi in get_tree().get_nodes_in_group("herois"):
		if not sala.is_ancestor_of(heroi):
			continue
		var sombra := Polygon2D.new()
		sombra.name = "SombraContato"
		sombra.z_index = 0
		sombra.show_behind_parent = true
		sombra.polygon = PackedVector2Array([Vector2(-8,-2),Vector2(-4,-4),Vector2(5,-4),Vector2(9,-1),Vector2(7,2),Vector2(-5,3),Vector2(-9,1)])
		sombra.color = Color(0.01, 0.02, 0.035, 0.38)
		heroi.add_child(sombra)
		heroi.move_child(sombra, 0)
		var sprite: AnimatedSprite2D = heroi.get_node("Visual/AnimatedSprite2D")
		var quadro := sprite.sprite_frames.get_frame_texture("idle_down", 0)
		var visivel := quadro.get_image().get_used_rect()
		var topo := floorf(sprite.position.y + (visivel.position.y - quadro.get_height() * 0.5 + sprite.offset.y) * sprite.scale.y)
		heroi.barra_vida.offset_top = topo - 6
		heroi.barra_vida.offset_bottom = topo - 3
		heroi.nome_label.offset_top = topo - (22 if heroi.barra_vida.visible else 16)
		heroi.nome_label.offset_bottom = topo - (9 if heroi.barra_vida.visible else 3)
		heroi.nome_label.add_theme_font_size_override("font_size", 9)
		herois.append({"no": heroi, "anterior": heroi.global_position, "distancia": 0.0, "sombra": sombra})
	if sala.has_signal("efeito_puzzle"):
		sala.efeito_puzzle.connect(celebrar)
	sala.get_node("AmbienteMasmorra").evento_ambiente.connect(_evento_audio)

func _evento_audio(tipo: StringName) -> void:
	if tipo != &"gota" or not MAPAS.FASES.has(sala.fase_historia) or particulas.size() >= 96:
		return
	var ambiente := sala.get_node("AmbienteMasmorra")
	var ponto: Vector2 = ambiente.fontes[ambiente.ultima_fonte]
	if sala.fase_historia == 2 and sala.resolvida:
		var ponte: Rect2i = MAPAS.FASES[2].ponte
		if Rect2(Vector2(ponte.position) * 24, Vector2(ponte.size) * 24).grow(10).has_point(ponto):
			return
	particulas.append({"p": ponto - Vector2(0, 12), "v": Vector2(0, 28), "vida": 0.43, "total": 0.43, "cor": Color(0.55,0.82,0.9,0.6), "tamanho": 1.0, "gota": true})

func _luz(pai: Node2D, ponto: Vector2, cor: Color, energia: float, escala: float = 1.0) -> PointLight2D:
	var luz := PointLight2D.new()
	luz.texture = textura_luz
	luz.position = ponto
	luz.color = cor
	luz.energy = energia
	luz.texture_scale = escala
	pai.add_child(luz)
	return luz

func _preparar_sala() -> void:
	if MAPAS.FASES.has(sala.fase_historia):
		var dados: Dictionary = MAPAS.FASES[sala.fase_historia]
		var reservatorio: TileMapLayer = sala.get_node("Reservatorios")
		var material_agua := ShaderMaterial.new()
		material_agua.shader = AGUA
		var regioes := PackedVector4Array()
		for zona: Rect2i in dados.agua:
			regioes.append(Vector4(zona.position.x * 24, zona.position.y * 24, zona.size.x * 24, zona.size.y * 24))
		material_agua.set_shader_parameter("tanques", regioes)
		material_agua.set_shader_parameter("quantidade", regioes.size())
		reservatorio.material = material_agua
		reservatorio.modulate = Color.WHITE
		for no in sala.get_children():
			if no is PointLight2D and no.name != "LuzSaida":
				luzes.append({"no": no, "base": no.energy, "fase": luzes.size() * 1.7})
		for alvo in sala.get_node("Alvos").get_children():
			_registrar_cristal(alvo, alvo.get_node("Imagem"))
	else:
		_adicionar_tochas_fase3()
		for objeto in sala.get_node("objects").get_children():
			if objeto.has_method("get_state") and objeto.has_node("animation"):
				_registrar_cristal(objeto, objeto.get_node("animation"))

func _registrar_cristal(no: Node2D, imagem: AnimatedSprite2D) -> void:
	var luz := _luz(no, imagem.position, Color("75cee2"), 0.1, 0.65)
	cristais.append({"no": no, "imagem": imagem, "luz": luz, "estado": str(imagem.animation)})

func _adicionar_tochas_fase3() -> void:
	var terreno: TileMapLayer = sala.get_node("Terrain map layer")
	var colocadas: Array[Vector2] = []
	var quadros := SpriteFrames.new()
	quadros.set_animation_speed("default", 7)
	for i in 6:
		var atlas := AtlasTexture.new()
		atlas.atlas = FOGO
		atlas.region = Rect2(88, i * 48, 44, 48)
		quadros.add_frame("default", atlas)
	for celula in terreno.get_used_cells():
		var tile := terreno.get_cell_tile_data(celula)
		var acima := terreno.get_cell_tile_data(celula + Vector2i.UP)
		if tile == null or acima == null or tile.get_collision_polygons_count(0) > 0:
			continue
		if tile.get_collision_polygons_count(1) > 0 or acima.get_collision_polygons_count(0) == 0:
			continue
		var ponto := terreno.to_global(terreno.map_to_local(celula))
		var proximo := false
		for anterior in colocadas:
			if anterior.distance_to(ponto) < 130:
				proximo = true
		for objeto in sala.get_node("objects").get_children():
			if objeto is Node2D and objeto.global_position.distance_to(ponto) < 40:
				proximo = true
		if proximo:
			continue
		colocadas.append(ponto)
		var chama := AnimatedSprite2D.new()
		chama.sprite_frames = quadros
		chama.scale = Vector2.ONE * 0.55
		chama.position = sala.to_local(ponto) - Vector2(0, 7)
		chama.z_index = 2
		sala.add_child(chama)
		chama.play()
		chama.frame = colocadas.size() % 6
		var luz := _luz(sala, chama.position, Color("ffd294"), 0.5, 1.15)
		luzes.append({"no": luz, "base": 0.5, "fase": colocadas.size() * 1.7})
		if colocadas.size() >= 9:
			break

func celebrar(ponto: Vector2, tipo: StringName) -> void:
	var cor := Color("ffe1a0") if tipo in [&"acerto", &"saida", &"ponte"] else Color("9bdeeb")
	var quantidade := 16 if tipo in [&"acerto", &"saida"] else 8
	for i in quantidade:
		if particulas.size() >= 96:
			break
		var angulo := TAU * float(i) / quantidade
		particulas.append({"p": ponto, "v": Vector2.from_angle(angulo) * aleatorio.randf_range(14, 30), "vida": 0.65, "total": 0.65, "cor": cor, "tamanho": 2.0})

func _process(delta: float) -> void:
	tempo += delta
	for registro in luzes:
		registro.no.energy = registro.base * (1.0 + sin(tempo * 3.1 + registro.fase) * 0.045 + sin(tempo * 5.7 + registro.fase) * 0.025)
	for cristal in cristais:
		var estado := str(cristal.imagem.animation)
		cristal.luz.color = Color("ffdb8f") if estado == "gold" else Color("82d4e9")
		cristal.luz.energy = (0.38 if estado in ["gold", "blue"] else 0.06) * (1.0 + sin(tempo * 2) * 0.08)
		if estado != cristal.estado:
			if estado == "gold":
				celebrar(to_local(cristal.no.global_position), &"acerto")
			cristal.estado = estado
	for registro in herois:
		var heroi = registro.no
		var passo: float = heroi.global_position.distance_to(registro.anterior)
		registro.anterior = heroi.global_position
		registro.sombra.visible = not heroi.esta_morto
		registro.sombra.scale = Vector2.ONE * (0.75 if heroi.pulando else 1.0)
		if passo < 0.05 or passo > 12 or heroi.pulando or heroi.esta_morto:
			continue
		registro.distancia += passo
		if registro.distancia > 17 and particulas.size() < 96:
			registro.distancia = 0.0
			particulas.append({"p": to_local(heroi.global_position) + Vector2(0, 2), "v": Vector2(aleatorio.randf_range(-3, 3), -4), "vida": 0.35, "total": 0.35, "cor": Color(0.65, 0.64, 0.58, 0.32), "tamanho": 1.0})
	for i in range(particulas.size() - 1, -1, -1):
		var particula := particulas[i]
		particula.vida -= delta
		particula.p += particula.v * delta
		if particula.vida <= 0:
			if particula.get("gota", false) and ondas.size() < 12:
				ondas.append({"p": particula.p, "vida": 1.0})
			particulas.remove_at(i)
	for i in range(ondas.size() - 1, -1, -1):
		ondas[i].vida -= delta
		if ondas[i].vida <= 0:
			ondas.remove_at(i)
	faiscas_em -= delta
	if faiscas_em <= 0 and not luzes.is_empty() and particulas.size() < 96:
		faiscas_em = 0.2
		var registro: Dictionary = luzes[aleatorio.randi_range(0, luzes.size() - 1)]
		particulas.append({"p": to_local(registro.no.global_position), "v": Vector2(aleatorio.randf_range(-4, 4), -12), "vida": 0.8, "total": 0.8, "cor": Color(1, 0.65, 0.25, 0.45), "tamanho": 1.0})
	queue_redraw()

func _draw() -> void:
	for particula in particulas:
		var cor: Color = particula.cor
		cor.a *= clampf(particula.vida / particula.total, 0, 1)
		draw_rect(Rect2(Vector2(particula.p).round(), Vector2.ONE * particula.tamanho), cor)
	for onda in ondas:
		var pontos := PackedVector2Array()
		var raio: float = 2 + (1.0 - onda.vida) * 8
		for i in 13:
			pontos.append((Vector2(onda.p) + Vector2.from_angle(float(i) * TAU / 12) * Vector2(raio, raio * 0.4)).round())
		draw_polyline(pontos, Color(0.45,0.75,0.83,onda.vida * 0.3), 1)
