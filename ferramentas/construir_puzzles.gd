extends SceneTree
## Regenera somente as fases 01, 02 e 04; nunca regrava area_3.
const MAPAS = preload("res://recursos/mapas_puzzle.gd")
const ARTE = "res://assets/mapa/CRAFTPIX_DUNGEON/"
var raiz: Node2D
var tiles: TileSet

func _initialize() -> void:
	call_deferred("executar")

func anexar(no: Node, pai: Node = null) -> Node:
	if pai == null:
		pai = raiz
	if String(no.name).is_empty():
		no.name = no.get_class()+"_%02d"%pai.get_child_count()
	pai.add_child(no)
	no.owner = raiz
	return no

func atlas(arquivo: String, regiao: Rect2) -> AtlasTexture:
	var t := AtlasTexture.new()
	t.atlas = load(ARTE+arquivo)
	t.region = regiao
	return t

func centro(ponto: Vector2i) -> Vector2:
	return Vector2(ponto)*24+Vector2(12,12)

func corpo(nome: String, regiao: Rect2, pai: Node = null) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = nome
	b.position = regiao.get_center()
	b.collision_layer = 1
	b.collision_mask = 0
	anexar(b,pai)
	var c := CollisionShape2D.new()
	c.name = "shape"
	var forma := RectangleShape2D.new()
	forma.size = regiao.size
	c.shape = forma
	anexar(c,b)
	return b

func criar_tiles() -> void:
	tiles = TileSet.new()
	tiles.tile_size = Vector2i(16,16)
	tiles.add_physics_layer()
	tiles.set_physics_layer_collision_layer(0,1)
	tiles.set_physics_layer_collision_mask(0,6)
	for fonte in 2:
		var a := TileSetAtlasSource.new()
		a.texture = load(ARTE+"walls_floor.png")
		a.texture_region_size = Vector2i(16,16)
		tiles.add_source(a,fonte)
		for y in 14:
			for x in 10:
				var p := Vector2i(x,y)
				var usados := [Vector2i(2,8),Vector2i(7,13),Vector2i(8,13),Vector2i(9,13),Vector2i(1,8),Vector2i(3,8),Vector2i(2,7),Vector2i(2,9),Vector2i(5,1),Vector2i(6,1),Vector2i(7,1)] if fonte == 0 else [Vector2i(6,2),Vector2i(6,4),Vector2i(5,2),Vector2i(7,2)]
				if p not in usados:
					continue
				a.create_tile(p)
				if fonte == 1:
					var d := a.get_tile_data(p,0)
					d.set_collision_polygons_count(0,1)
					d.set_collision_polygon_points(0,0,PackedVector2Array([Vector2(-8,-8),Vector2(8,-8),Vector2(8,8),Vector2(-8,8)]))
	var agua := TileSetAtlasSource.new()
	agua.texture = load("res://assets/Tiny Swords (Free Pack)/Terrain/Tileset/Water Background color.png")
	agua.texture_region_size = Vector2i(16,16)
	agua.create_tile(Vector2i.ZERO)
	tiles.add_source(agua,2)
	var pedra := TileSetAtlasSource.new()
	pedra.texture = load("res://assets/Ninja Adventure - Asset Pack/Backgrounds/Tilesets/TilesetInteriorFloor.png")
	pedra.texture_region_size = Vector2i(16,16)
	tiles.add_source(pedra,3)
	for y in range(13,16):
		for x in range(12,17):
			pedra.create_tile(Vector2i(x,y))

func camada(nome: String, z: int) -> TileMapLayer:
	var no := TileMapLayer.new()
	no.name = nome
	no.tile_set = tiles
	no.scale = Vector2.ONE*1.5
	no.z_index = z
	anexar(no)
	return no

func celulas(retangulos: Array) -> Dictionary:
	var conjunto := {}
	for r: Rect2i in retangulos:
		for y in range(r.position.y,r.end.y):
			for x in range(r.position.x,r.end.x):
				conjunto[Vector2i(x,y)] = true
	return conjunto

func etiqueta(texto: String, ponto: Vector2, pai: Node = null, cor: Color = Color("#e3d4aa")) -> Label:
	var l := Label.new()
	l.text = texto
	l.position = ponto
	l.add_theme_font_size_override("font_size",11)
	l.add_theme_color_override("font_color",cor)
	l.add_theme_color_override("font_shadow_color",Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x",1)
	l.add_theme_constant_override("shadow_offset_y",1)
	l.z_index = 3
	anexar(l,pai)
	return l

func objeto(tipo: String, ponto: Vector2, pai: Node) -> void:
	var recortes := {"caixa":Rect2(80,80,16,16),"barril":Rect2(192,80,16,16),"urna":Rect2(208,80,16,16),"bau":Rect2(144,16,32,16),"estante":Rect2(64,80,16,32),"coluna":Rect2(0,0,16,32),"cama":Rect2(0,144,32,48)}
	var r: Rect2 = recortes[tipo]
	var no := Node2D.new()
	no.name = tipo.capitalize()+"_%02d"%pai.get_child_count()
	no.position = ponto
	no.y_sort_enabled = true
	anexar(no,pai)
	var sombra := Polygon2D.new()
	sombra.polygon = PackedVector2Array([Vector2(-11,-3),Vector2(11,-3),Vector2(14,2),Vector2(8,5),Vector2(-10,4)])
	sombra.color = Color(0.02,0.02,0.04,0.28)
	anexar(sombra,no)
	var sprite := Sprite2D.new()
	if tipo in ["cama","coluna"]:
		var t := AtlasTexture.new()
		t.atlas = load("res://assets/Ninja Adventure - Asset Pack/Backgrounds/Tilesets/tileset_bed.png" if tipo == "cama" else "res://assets/Dungeon Gathering Free Version/Structure.png")
		t.region = r
		sprite.texture = t
	else:
		sprite.texture = atlas("Objects.png",r)
	var escala := 1.0 if tipo == "cama" else 1.5
	sprite.scale = Vector2.ONE*escala
	sprite.position.y = -r.size.y*escala/2+3
	anexar(sprite,no)
	corpo("Apoio",Rect2(-8,-4,16,8),no)

func grade(nome: String, regiao: Rect2i) -> void:
	var grupo := Node2D.new()
	grupo.name = nome
	anexar(grupo)
	for p: Vector2i in celulas([regiao]):
		var parte := load("res://cenas/objects/non-interactable/fence.tscn").instantiate() as Node2D
		parte.position = centro(p)
		if regiao.size.y > regiao.size.x:
			parte.rotation = PI/2
		anexar(parte,grupo)

func roda(ponto: Vector2i) -> void:
	var no := Node2D.new()
	no.name = "MecanismoNico"
	no.position = centro(ponto)
	no.set_script(load("res://scripts/areas/trava_puzzle.gd"))
	anexar(no)
	var apoio := Sprite2D.new()
	apoio.texture = atlas("Objects.png",Rect2(16,80,32,32))
	apoio.scale = Vector2.ONE*0.8
	anexar(apoio,no)
	var imagem := Sprite2D.new()
	imagem.name = "Imagem"
	imagem.texture = atlas("Objects.png",Rect2(96,112,16,16))
	imagem.position.y = -12
	imagem.scale = Vector2.ONE*1.5
	anexar(imagem,no)
	var area := Area2D.new()
	area.collision_layer = 16
	area.collision_mask = 0
	area.position.y = -8
	anexar(area,no)
	var shape := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 18
	shape.shape = circulo
	anexar(shape,area)
	etiqueta("NICO · F",centro(ponto)+Vector2(-22,16))

func animacao_fogo(p: Vector2) -> void:
	var chama := AnimatedSprite2D.new()
	chama.position = p-Vector2(0,4)
	chama.scale = Vector2.ONE*0.75
	chama.z_index = 2
	var quadros := SpriteFrames.new()
	quadros.set_animation_speed("default",7)
	for i in 6:
		quadros.add_frame("default",atlas("fire_animation.png",Rect2(88,i*48,44,48)))
	chama.sprite_frames = quadros
	chama.autoplay = "default"
	anexar(chama)
	var apoio := Sprite2D.new()
	apoio.texture = atlas("Objects.png",Rect2(16,80,16,32))
	apoio.scale = Vector2.ONE
	apoio.position = p+Vector2(0,5)
	apoio.z_index = 1
	anexar(apoio)
	criar_luz(p,0.4)

func criar_luz(p: Vector2, energia: float) -> PointLight2D:
	var grad := Gradient.new()
	grad.set_color(0,Color(1,1,1,0.55))
	grad.set_color(1,Color(1,1,1,0))
	var luz_tex := GradientTexture2D.new()
	luz_tex.gradient = grad
	luz_tex.width = 96
	luz_tex.height = 96
	luz_tex.fill = GradientTexture2D.FILL_RADIAL
	luz_tex.fill_from = Vector2(0.5,0.5)
	luz_tex.fill_to = Vector2(1,0.5)
	var luz := PointLight2D.new()
	luz.texture = luz_tex
	luz.position = p
	luz.color = Color("#ffd589")
	luz.energy = energia
	anexar(luz)
	return luz

func placa(nome: String, p: Vector2, pai: Node = null) -> Node2D:
	var no := load("res://cenas/objects/interactables/button.tscn").instantiate() as Node2D
	no.name = nome
	no.position = p
	no.channel = StringName("puzzle_%d_%s"%[raiz.mapa_id,nome])
	anexar(no,pai)
	return no

func criar_alvo(id: int, p: Vector2i, pai: Node) -> void:
	var original: Node = load("res://cenas/objects/interactables/switch.tscn").instantiate()
	var alvo := Node2D.new()
	alvo.name = "Alvo%d"%(id+1)
	alvo.set_script(load("res://scripts/areas/alvo_puzzle.gd"))
	alvo.indice = id
	alvo.position = centro(p)
	anexar(alvo,pai)
	var base := Sprite2D.new()
	base.name = "Coluna"
	var pedra := AtlasTexture.new()
	# Mesmas duas peças que sustentam os cristais na Object map layer da area_3.
	pedra.atlas = load("res://assets/Dungeon Gathering Free Version/Set 1.png")
	pedra.region = Rect2(128,288,16,32)
	base.texture = pedra
	base.scale = Vector2.ONE*1.5
	base.position.y = 12
	anexar(base,alvo)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Imagem"
	sprite.sprite_frames = original.get_node("animation").sprite_frames
	sprite.scale = Vector2.ONE*1.3
	sprite.position.y = -10.4
	anexar(sprite,alvo)
	original.free()
	var area := Area2D.new()
	area.collision_layer = 16
	area.collision_mask = 0
	area.position.y = -12
	anexar(area,alvo)
	var shape := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 19
	shape.shape = circulo
	anexar(shape,area)

func construir(numero: int) -> void:
	var dados: Dictionary = MAPAS.FASES[numero]
	raiz = Node2D.new()
	raiz.name = "Puzzle%02d"%numero
	raiz.set_script(load("res://scripts/areas/sala_puzzle.gd"))
	raiz.mapa_id = numero
	raiz.fase_historia = numero
	raiz.y_sort_enabled = true
	raiz.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var fundo := Polygon2D.new()
	fundo.polygon = PackedVector2Array([Vector2(-100,-100),Vector2(900,-100),Vector2(900,700),Vector2(-100,700)])
	fundo.color = Color("#10141e")
	fundo.z_index = -10
	anexar(fundo)
	var pisos := celulas(dados.salas)
	var agua := celulas(dados.agua)
	for p: Vector2i in agua:
		pisos.erase(p)
	var todos := pisos.duplicate()
	todos.merge(agua)
	var chao := camada("Piso",-4)
	chao.modulate = Color.WHITE.lerp(dados.tom,0.18)
	var pedra_material := ShaderMaterial.new()
	pedra_material.shader = load("res://recursos/pedra_puzzles.gdshader")
	chao.material = pedra_material
	var paredes := camada("Paredes",0)
	var coroamento := camada("Coroamento",-1)
	var aguas := camada("Reservatorios",-5)
	aguas.modulate = Color(0.42,0.59,0.70)
	for p: Vector2i in pisos:
		var coordenada := Vector2i(2,8)
		if posmod(p.x*23+p.y*37,31) == 0:
			coordenada = Vector2i(7+posmod(p.x+p.y,3),13)
		if agua.has(p+Vector2i.LEFT): coordenada = Vector2i(1,8)
		elif agua.has(p+Vector2i.RIGHT): coordenada = Vector2i(3,8)
		elif agua.has(p+Vector2i.UP): coordenada = Vector2i(2,7)
		elif agua.has(p+Vector2i.DOWN): coordenada = Vector2i(2,9)
		if coordenada == Vector2i(2,8):
			chao.set_cell(p,3,Vector2i(12+posmod(p.x,4),13+posmod(p.y,3)))
		else:
			chao.set_cell(p,0,coordenada)
	for r: Rect2i in dados.tapetes:
		for p: Vector2i in celulas([r]):
			if pisos.has(p):
				chao.set_cell(p,0,Vector2i(7+posmod(p.x+p.y,3),13))
	for p: Vector2i in agua:
		aguas.set_cell(p,2,Vector2i.ZERO)
	var bordas := {}
	for p: Vector2i in todos:
		for y in range(-1,2):
			for x in range(-1,2):
				var vizinho := p+Vector2i(x,y)
				if not todos.has(vizinho):
					bordas[vizinho] = true
	for p: Vector2i in bordas:
		var tile := Vector2i(6,2)
		if todos.has(p+Vector2i.UP): tile = Vector2i(6,4)
		elif todos.has(p+Vector2i.RIGHT): tile = Vector2i(5,2)
		elif todos.has(p+Vector2i.LEFT): tile = Vector2i(7,2)
		paredes.set_cell(p,1,tile)
		if pisos.has(p+Vector2i.DOWN) and not todos.has(p+Vector2i.UP):
			var cap := Vector2i(6,1)
			if not pisos.has(p+Vector2i(-1,1)): cap = Vector2i(5,1)
			elif not pisos.has(p+Vector2i(1,1)): cap = Vector2i(7,1)
			coroamento.set_cell(p+Vector2i.UP,0,cap)
	var props := Node2D.new()
	props.name = "Objetos"
	props.y_sort_enabled = true
	anexar(props)
	for item in dados.props:
		objeto(item[2],centro(Vector2i(item[0],item[1])),props)
	for p: Vector2i in dados.tochas:
		animacao_fogo(centro(p))
	# Cada célula de água bloqueia os heróis, exceto o leito da ponte móvel.
	var bloqueadas := agua.duplicate()
	if numero == 2:
		for p: Vector2i in celulas([dados.ponte]):
			bloqueadas.erase(p)
	# Mescla horizontalmente: poucas formas físicas, mantendo os contornos dos tanques.
	for y in dados.tamanho.y:
		var x := 0
		while x < dados.tamanho.x:
			if not bloqueadas.has(Vector2i(x,y)):
				x += 1
				continue
			var inicio := x
			while bloqueadas.has(Vector2i(x,y)):
				x += 1
			corpo("Agua_%d_%d"%[inicio,y],Rect2(inicio*24,y*24,(x-inicio)*24,24))
	for r: Rect2i in dados.agua:
		if r.size.x < 2 or r.size.y < 2:
			continue
		var onda := AnimatedSprite2D.new()
		onda.position = (Vector2(r.position)+Vector2(r.size)/2)*24
		onda.scale = Vector2.ONE*0.65
		if numero == 2 and Rect2(Vector2(dados.ponte.position)*24,Vector2(dados.ponte.size)*24).grow(20).has_point(onda.position):
			onda.position = Vector2(r.position)*24+Vector2(24,24)
		onda.z_index = -3
		var frames := SpriteFrames.new()
		frames.set_animation_speed("default",4)
		for i in 6:
			frames.add_frame("default",atlas("water_details_animation.png",Rect2(528,i*208,48,48)))
		onda.sprite_frames = frames
		onda.autoplay = "default"
		anexar(onda)
	if numero != 2:
		placa("PlacaNico",centro(dados.placa))
		etiqueta("NICO",centro(dados.placa)+Vector2(-15,13))
	if numero == 1:
		placa("PlacaOtto",centro(dados.placa_otto))
		etiqueta("OTTO",centro(dados.placa_otto)+Vector2(-15,13),null,Color("#93d9de"))
		grade("GradeFinal",dados.grade_final)
	roda(dados.mecanismo)
	var alvos := Node2D.new()
	alvos.name = "Alvos"
	anexar(alvos)
	for i in dados.alvos.size():
		criar_alvo(i,dados.alvos[i],alvos)
		if numero == 2:
			etiqueta(["○","△","□"][i],centro(dados.alvos[i])+Vector2(-5,15))
	if numero == 2:
		var pistas := Node2D.new()
		pistas.name = "Pistas"
		anexar(pistas)
		for i in 3:
			var p: Vector2 = centro(dados.pistas[i])
			var pedra := Sprite2D.new()
			pedra.texture = atlas("Objects.png",Rect2(16,80,32,32))
			pedra.position = p
			pedra.scale = Vector2.ONE*0.9
			anexar(pedra,pistas)
			var l := etiqueta(["1 · △","2 · ○","3 · □"][i],p+Vector2(-17,-21),pistas)
			l.name = "Pista%d"%i
			l.modulate.a = 0.35
		var ponte := camada("Ponte",-3)
		ponte.hide()
		for p: Vector2i in celulas([dados.ponte]):
			var borda: Vector2i = Vector2i(2,7) if p.y == dados.ponte.position.y else (Vector2i(2,9) if p.y == dados.ponte.end.y-1 else Vector2i(7+posmod(p.x,3),13))
			ponte.set_cell(p,0,borda)
		var sombra_ponte := Polygon2D.new()
		var r := Rect2(Vector2(dados.ponte.position)*16+Vector2(0,5),Vector2(dados.ponte.size)*16)
		sombra_ponte.polygon = PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
		sombra_ponte.color = Color(0,0,0,0.25)
		sombra_ponte.z_index = -1
		anexar(sombra_ponte,ponte)
		corpo("BloqueioPonte",Rect2(Vector2(dados.ponte.position)*24,Vector2(dados.ponte.size)*24))
	else:
		grade("Grade",dados.grade)
	if numero == 4:
		var finais := Node2D.new()
		finais.name = "PlacasFinais"
		anexar(finais)
		for i in 2:
			placa("Amigo%d"%i,centro(dados.placas_finais[i]),finais)
		etiqueta("JUNTOS",centro(Vector2i(17,4)))
		var espelho := corpo("Espelho",Rect2(Vector2(-24,-4),Vector2(48,8)))
		espelho.set_script(load("res://scripts/areas/espelho_puzzle.gd"))
		espelho.position = centro(dados.espelho)
		espelho.rotation = 0
		var reflexo := Sprite2D.new()
		reflexo.texture = atlas("Objects.png",Rect2(96,112,16,16))
		reflexo.scale = Vector2(3,0.5)
		anexar(reflexo,espelho)
		etiqueta("SEGURE O CLIQUE",centro(dados.tiro)+Vector2(-35,22),null,Color("#93d9de"))
	var porta := AnimatedSprite2D.new()
	porta.name = "Porta"
	porta.position = centro(dados.porta)-Vector2(0,24)
	porta.scale = Vector2.ONE*1.5
	var porta_frames := SpriteFrames.new()
	porta_frames.add_animation("abrir")
	porta_frames.set_animation_loop("abrir",false)
	porta_frames.set_animation_speed("abrir",7)
	for i in 5:
		porta_frames.add_frame("abrir",atlas("doors_lever_chest_animation.png",Rect2(96,i*48,32,48)))
	porta.sprite_frames = porta_frames
	porta.animation = "abrir"
	anexar(porta)
	var luz_saida := criar_luz(centro(dados.saida),0)
	luz_saida.name = "LuzSaida"
	luz_saida.texture_scale = 2
	var personagens := Node2D.new()
	personagens.name = "Personagens"
	personagens.y_sort_enabled = true
	anexar(personagens)
	for i in 2:
		var heroi := load("res://cenas/personagens/player%d.tscn"%(i+1)).instantiate() as Node2D
		heroi.name = "Nico" if i == 0 else "Otto"
		heroi.position = centro(dados.inicios[i]) if dados.has("inicios") else centro(dados.inicio)+Vector2(-24 if i == 0 else 24,0)
		heroi.nome_personagem = heroi.name
		anexar(heroi,personagens)
	if not dados.has("inicios"):
		var spawn := load("res://cenas/objects/respawn/level_spawn.tscn").instantiate() as Node2D
		spawn.position = centro(dados.inicio)
		spawn.team_spacing = 48
		anexar(spawn)
	var camera := Camera2D.new()
	camera.name = "Camera"
	camera.position = centro(dados.inicio)
	anexar(camera)
	var saida := load("res://cenas/objects/level_specifics/level_end.tscn").instantiate() as Area2D
	saida.name = "Saida"
	saida.position = centro(dados.saida)
	saida.monitoring = false
	saida.proxima_cena = "res://cenas/areas/puzzle_02.tscn" if numero == 1 else ("res://cenas/areas/area_3.tscn" if numero == 2 else "res://cenas/screens/fim_aventura.tscn")
	var area_saida := RectangleShape2D.new()
	area_saida.size = Vector2(90,64)
	saida.get_node("shape").shape = area_saida
	anexar(saida)
	var segredos := Node2D.new()
	segredos.name = "Segredos"
	anexar(segredos)
	for p: Vector2i in dados.segredos:
		var estrela := Sprite2D.new()
		estrela.position = centro(p)
		estrela.texture = load("res://assets/Ninja Adventure - Asset Pack/Items/Resource/GemYellow.png")
		estrela.scale = Vector2.ONE*1.5
		estrela.modulate = Color("#c9c8a6")
		anexar(estrela,segredos)
	var ambiente := Node2D.new()
	ambiente.set_script(load("res://scripts/areas/ambiente_sala.gd"))
	ambiente.z_index = -2
	anexar(ambiente)
	var cena := PackedScene.new()
	assert(cena.pack(raiz) == OK)
	var caminho := "res://cenas/areas/puzzle_%02d.tscn"%numero
	backup(caminho)
	assert(ResourceSaver.save(cena,caminho) == OK)
	raiz.free()
	print("Mapa %d salvo: %d células de piso, %d objetos, %d tochas"%[numero,pisos.size(),dados.props.size(),dados.tochas.size()])

func executar() -> void:
	criar_tiles()
	backup("res://recursos/puzzles_tileset.tres")
	assert(ResourceSaver.save(tiles,"res://recursos/puzzles_tileset.tres") == OK)
	tiles.take_over_path("res://recursos/puzzles_tileset.tres")
	for numero in [1,2,4]:
		construir(numero)
	quit()

func backup(caminho: String) -> void:
	if not FileAccess.file_exists(caminho):
		return
	DirAccess.make_dir_recursive_absolute("res://backups/puzzles")
	if not FileAccess.file_exists("res://backups/.gdignore"):
		var ignore := FileAccess.open("res://backups/.gdignore",FileAccess.WRITE)
		ignore.close()
	var destino := "res://backups/puzzles/%s_%d"%[caminho.get_file(),Time.get_ticks_usec()]
	assert(DirAccess.copy_absolute(caminho,destino) == OK)
