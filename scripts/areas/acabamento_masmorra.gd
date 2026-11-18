extends Node2D
## Acabamento aditivo: não move mapas, mecanismos ou formas de colisão.
const FOGO = preload("res://assets/mapa/CRAFTPIX_DUNGEON/fire_animation.png")
const VINHETA = preload("res://recursos/vinheta_masmorra.gdshader")
const SOM_CRISTAL = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Jingles/Success3.wav")
const SOM_PLACA = preload("res://assets/SONS/INTERFACE/CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg")
var sala: Node2D
var tempo := 0.0
var aleatorio := RandomNumberGenerator.new()
var luzes: Array[Dictionary] = []
var cristais: Array[Dictionary] = []
var herois: Array[Dictionary] = []
var particulas: Array[Dictionary] = []
var faiscas_em := 0.0
var textura_luz: GradientTexture2D
var vinheta: ColorRect
var som_mecanismo: AudioStreamPlayer2D
var bordas: Array[Rect2] = []
var desgaste := PackedVector2Array()
var profundidade: Node2D

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
	ambiente.color = [Color("c3cfec"), Color("bacde3"), Color("b3bddb")][sala.fase_historia - 1]
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
	som_mecanismo = AudioStreamPlayer2D.new()
	som_mecanismo.bus = &"SFX"
	som_mecanismo.max_distance = 950
	som_mecanismo.volume_db = -23
	add_child(som_mecanismo)
	_preparar_sala()
	for heroi in get_tree().get_nodes_in_group("herois"):
		if not sala.is_ancestor_of(heroi):
			continue
		var passos := preload("res://scripts/areas/passos_puzzle.gd").new()
		heroi.add_child(passos)
		var existente := heroi.get_node_or_null("Sombra") as CanvasItem
		if existente:
			existente.hide()
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
	sala.get_node("AmbienteMasmorra").evento_ambiente.connect(_evento_audio)

func _evento_audio(tipo: StringName) -> void:
	if tipo != &"gota" or particulas.size() >= 96:
		return
	var ambiente := sala.get_node("AmbienteMasmorra")
	var ponto: Vector2 = ambiente.fontes[ambiente.ultima_fonte]
	particulas.append({"p": ponto - Vector2(0, 12), "v": Vector2(0, 28), "vida": 0.43, "total": 0.43, "cor": Color(0.55, 0.82, 0.9, 0.6), "tamanho": 1.0})

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
	var campo := sala.get_node_or_null("HoleField") as HoleField
	var objetos := sala.get_node_or_null("objects")
	if campo and campo.tile_map_layer and objetos:
		_preparar_profundidade(campo)
		_adicionar_tochas(campo.tile_map_layer, objetos)
	if objetos:
		for objeto in objetos.get_children():
			if objeto.has_method("get_state") and objeto.has_node("animation"):
				_registrar_cristal(objeto, objeto.get_node("animation"))
			elif objeto.has_signal("state_changed"):
				objeto.state_changed.connect(_placa_alterada.bind(objeto))
			elif objeto is MovingPlatform:
				_marcar_plataforma(objeto)
	var saida := sala.get_node_or_null("level_end") as LevelEnd
	if saida:
		_luz(saida, Vector2.ZERO, Color("ffe3ac"), 0.42, 1.4)
		saida.saida_iniciada.connect(func(): celebrar(to_local(saida.global_position), &"saida"))

func _placa_alterada(pressionada: bool, placa: Node2D) -> void:
	if pressionada:
		celebrar(to_local(placa.global_position), &"placa")
		_tocar(to_local(placa.global_position), SOM_PLACA)

func _tocar(ponto: Vector2, stream: AudioStream) -> void:
	if HistoriaDupla.silenciado:
		return
	som_mecanismo.position = ponto
	som_mecanismo.stream = stream
	som_mecanismo.play()

func _preparar_profundidade(campo: HoleField) -> void:
	var terreno := campo.tile_map_layer
	var tamanho := Vector2(terreno.tile_set.tile_size)
	var escala := terreno.global_scale
	for celula in campo.obter_celulas():
		var vizinho := terreno.get_cell_tile_data(celula + Vector2i.UP)
		if vizinho == null or vizinho.get_collision_polygons_count(campo.scan_physics_layer) > 0:
			continue
		var canto := to_local(terreno.to_global(terreno.map_to_local(celula) - tamanho * 0.5))
		bordas.append(Rect2(canto, Vector2(tamanho.x * escala.x, 4)))
	for celula in terreno.get_used_cells():
		var piso := terreno.get_cell_tile_data(celula)
		if piso.get_collision_polygons_count(0) > 0 or piso.get_collision_polygons_count(campo.scan_physics_layer) > 0:
			continue
		var padrao := hash(celula)
		if posmod(padrao, 7) > 1:
			continue
		var meio := to_local(terreno.to_global(terreno.map_to_local(celula)))
		desgaste.append((meio + Vector2(posmod(padrao, 9) - 4, posmod(padrao, 5) - 2)).round())
	profundidade = Node2D.new()
	profundidade.name = "BordasDosVaos"
	profundidade.z_as_relative = false
	profundidade.z_index = terreno.z_index + 1
	profundidade.draw.connect(_desenhar_profundidade)
	add_child(profundidade)

func _desenhar_profundidade() -> void:
	for borda in bordas:
		profundidade.draw_rect(borda, Color(0.04, 0.055, 0.12, 0.42))
		profundidade.draw_rect(Rect2(borda.position, Vector2(borda.size.x, 1)), Color(0.48, 0.56, 0.76, 0.30))
	for ponto in desgaste:
		profundidade.draw_rect(Rect2(ponto, Vector2(4, 1)), Color(0.12, 0.16, 0.25, 0.27))
		profundidade.draw_rect(Rect2(ponto + Vector2(1, 1), Vector2(2, 1)), Color(0.65, 0.73, 0.88, 0.16))

func _marcar_plataforma(objeto: MovingPlatform) -> void:
	var trilho := Line2D.new()
	trilho.points = PackedVector2Array([to_local(objeto.inactive_anchor.global_position), to_local(objeto.active_anchor.global_position)])
	trilho.width = 2.0
	trilho.default_color = Color(0.36, 0.61, 0.73, 0.37)
	trilho.z_as_relative = false
	trilho.z_index = 0
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color(0.36, 0.61, 0.73, 0.23))
	gradiente.set_color(1, Color(0.60, 0.78, 0.85, 0.45))
	trilho.gradient = gradiente
	add_child(trilho)

func _registrar_cristal(no: Node2D, imagem: AnimatedSprite2D) -> void:
	var luz := _luz(no, imagem.position, Color("75cee2"), 0.1, 0.65)
	cristais.append({"no": no, "imagem": imagem, "luz": luz, "estado": str(imagem.animation)})

func _adicionar_tochas(terreno: TileMapLayer, objetos: Node) -> void:
	var colocadas: Array[Vector2] = []
	var quadros := SpriteFrames.new()
	quadros.set_animation_speed("default", 7)
	for i in 6:
		var atlas := AtlasTexture.new()
		atlas.atlas = FOGO
		atlas.region = Rect2(88, i * 48, 44, 48)
		quadros.add_frame("default", atlas)
	var celulas := terreno.get_used_cells()
	celulas.sort()
	for celula in celulas:
		var tile := terreno.get_cell_tile_data(celula)
		if tile == null or tile.get_collision_polygons_count(0) > 0:
			continue
		if tile.get_collision_polygons_count(1) > 0:
			continue
		var margem := false
		for direcao in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
			var vizinho := terreno.get_cell_tile_data(celula + direcao)
			if vizinho == null or vizinho.get_collision_polygons_count(0) > 0:
				margem = true
				break
		if not margem:
			continue
		var ponto := terreno.to_global(terreno.map_to_local(celula))
		var proximo := false
		for anterior in colocadas:
			if anterior.distance_to(ponto) < 205:
				proximo = true
		for objeto in objetos.get_children():
			if objeto is Node2D and objeto.global_position.distance_to(ponto) < 40:
				proximo = true
		if proximo:
			continue
		colocadas.append(ponto)
		var chama := AnimatedSprite2D.new()
		chama.sprite_frames = quadros
		chama.scale = Vector2.ONE * 0.55
		chama.position = to_local(ponto) - Vector2(0, 7)
		chama.z_index = 2
		add_child(chama)
		chama.play()
		chama.frame = colocadas.size() % 6
		var luz := _luz(self, chama.position, Color("ffd294"), 0.5, 1.15)
		luzes.append({"no": luz, "base": 0.5, "fase": colocadas.size() * 1.7})
		if colocadas.size() >= 18:
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
			if estado in ["gold", "blue"]:
				var ponto := to_local(cristal.no.global_position)
				celebrar(ponto, &"acerto")
				_tocar(ponto, SOM_CRISTAL)
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
			particulas.remove_at(i)
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
