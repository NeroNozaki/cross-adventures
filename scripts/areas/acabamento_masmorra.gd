extends Node2D
## Acabamento aditivo: não move mapas, mecanismos ou formas de colisão.
const DECORACAO = preload("res://scripts/areas/decoracao_masmorra.gd")
const RECEPTOR = preload("res://scripts/areas/receptor_masmorra.gd")
const SOM_GRADE = preload("res://assets/SONS/AMBIENTE/PORTAS_E_RANGIDOS/KENNEY_RPG_AUDIO/creak2.ogg")
const FOGO = preload("res://assets/mapa/CRAFTPIX_DUNGEON/fire_animation.png")
const VINHETA = preload("res://recursos/vinheta_masmorra.gdshader")
const SOM_CRISTAL = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Jingles/Success3.wav")
const SOM_PLACA = preload("res://assets/SONS/INTERFACE/CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg")
var sala: Node2D
var tempo := 0.0
var aleatorio := RandomNumberGenerator.new()
var luzes: Array[Dictionary] = []
var cristais: Array[Dictionary] = []
var placas: Array[Dictionary] = []
var herois: Array[Dictionary] = []
var particulas: Array[Dictionary] = []
var faiscas_em := 0.0
const COR_GOTA := Color(0.58, 0.85, 0.94, 0.77)
var ondas: Array[Dictionary] = []
var textura_luz: GradientTexture2D
var vinheta: ColorRect
var sons_mecanismos: Array[AudioStreamPlayer2D] = []
var bordas: Array[Rect2] = []
var decoracao: DECORACAO

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
	ambiente.color = [Color("c3c6d9"), Color("aac4cc"), Color("c4bbcf")][sala.fase_historia - 1]
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
	for _i in 3:
		var audio := AudioStreamPlayer2D.new()
		audio.bus = &"AmbMasmorra"
		audio.max_distance = 1000
		audio.attenuation = 0.65
		add_child(audio)
		sons_mecanismos.append(audio)
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
		var penumbra := Sprite2D.new()
		penumbra.texture = textura_luz
		penumbra.scale = Vector2(0.32, 0.14)
		penumbra.self_modulate = Color(0.01, 0.015, 0.035, 0.35)
		sombra.add_child(penumbra)
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
	var ambiente := sala.get_node("AmbienteMasmorra")
	var ponto := to_local(ambiente.to_global(ambiente.ponto_da_gota))
	if tipo == &"gota" and particulas.size() < 96:
		var duracao: float = ambiente.QUEDA_GOTA
		particulas.append({"p": ponto - Vector2(0, 11), "v": Vector2(0, 11.0 / duracao),
			"vida": duracao, "total": duracao, "cor": COR_GOTA, "tamanho": 1.0, "gota": true})
	elif tipo == &"impacto_gota":
		ondas.append({"ponto": ponto, "tempo": 0.0})
		for direcao in [-1.0, 1.0]:
			if particulas.size() >= 96:
				break
			particulas.append({"p": ponto, "v": Vector2(direcao * 11.0, -6.0),
				"vida": 0.20, "total": 0.20, "cor": COR_GOTA, "tamanho": 1.0})

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
		decoracao = DECORACAO.new()
		decoracao.name = "Alvenaria"
		add_child(decoracao)
		decoracao.montar(sala, campo, objetos, sala.fase_historia - 1)
		bordas = decoracao.vaos
		_adicionar_tochas(decoracao.arandelas)
	if objetos:
		for objeto in objetos.get_children():
			if objeto.has_method("get_state") and objeto.has_node("animation"):
				_registrar_cristal(objeto, objeto.get_node("animation"))
			elif objeto.has_signal("state_changed"):
				objeto.state_changed.connect(_placa_alterada.bind(objeto))
				var luz_placa := _luz(objeto, Vector2.ZERO, Color("82d4e9"), 0.14, 0.65)
				placas.append({"no": objeto, "luz": luz_placa})
			elif objeto is MovingPlatform:
				_marcar_plataforma(objeto)
			elif objeto is Fence or objeto is FenceSet:
				_ligar_som_grade(objeto)
	var saida := sala.get_node_or_null("level_end") as LevelEnd
	if saida:
		_luz(saida, Vector2.ZERO, Color("ffe3ac"), 0.42, 1.4)
		saida.saida_iniciada.connect(func(): celebrar(to_local(saida.global_position), &"saida"))

func _placa_alterada(pressionada: bool, placa: Node2D) -> void:
	if pressionada:
		celebrar(to_local(placa.global_position), &"placa")
		_tocar(to_local(placa.global_position), SOM_PLACA)

func _tocar(ponto: Vector2, stream: AudioStream, volume := -19.0, tom := 1.0) -> void:
	if HistoriaDupla.silenciado:
		return
	for audio in sons_mecanismos:
		if audio.playing:
			continue
		audio.position = ponto
		audio.stream = stream
		audio.volume_db = volume
		audio.pitch_scale = tom
		audio.play()
		return

func _ligar_som_grade(grade: Node2D) -> void:
	var quadros := grade.get_node_or_null("animation") as AnimatedSprite2D
	if grade is FenceSet:
		for parte in grade.find_children("*", "Node2D", true, false):
			if parte is Fence:
				quadros = parte.animation
				break
	if quadros:
		quadros.animation_changed.connect(_som_grade.bind(grade, quadros))

func _som_grade(grade: Node2D, quadros: AnimatedSprite2D) -> void:
	if quadros.animation == &"lowering" or quadros.animation == &"rising":
		_tocar(to_local(grade.global_position), SOM_GRADE, -22.0, 0.8 if quadros.animation == &"lowering" else 0.94)

func _marcar_plataforma(objeto: MovingPlatform) -> void:
	var trilho := Node2D.new()
	trilho.name = "TrilhoDaPlataforma"
	trilho.z_as_relative = false
	trilho.z_index = 0
	add_child(trilho)
	var inicio := to_local(objeto.inactive_anchor.global_position)
	var fim := to_local(objeto.active_anchor.global_position)
	var eixo := inicio.direction_to(fim)
	var transversal := eixo.orthogonal()
	var distancia := inicio.distance_to(fim)
	var cor := Color("537777") if sala.fase_historia == 2 else Color("756c60")
	trilho.draw.connect(func():
		for lado in [-1, 1]:
			var deslocamento := transversal * float(lado) * 3.0
			trilho.draw_line(inicio + deslocamento, fim + deslocamento, Color(cor, 0.66), 1.0)
		for passo in range(11, floori(distancia - 8.0), 13):
			var ponto := (inicio + eixo * float(passo)).round()
			trilho.draw_line(ponto - transversal * 4.0, ponto + transversal * 4.0, Color(cor, 0.31), 1.0)
		for ponta in [inicio, fim]:
			var base: Vector2 = ponta + transversal * 9.0
			trilho.draw_rect(Rect2(base - Vector2(3, 2), Vector2(6, 4)), Color("293847"))
			trilho.draw_rect(Rect2(base - Vector2(2, 1), Vector2(4, 2)), cor)
	)

	var estrado := Node2D.new()
	estrado.name = "RebitesDoEstrado"
	estrado.z_index = 1
	objeto.platform.add_child(estrado)
	var bloqueio := objeto.obter_retangulo_bloqueio()
	if not bloqueio.has_area():
		return
	var canto := estrado.to_local(bloqueio.position).round()
	var medida := estrado.to_local(bloqueio.end).round() - canto
	estrado.draw.connect(func():
		var frente := canto + Vector2(1, medida.y - 3)
		estrado.draw_rect(Rect2(frente, Vector2(medida.x - 2, 3)), Color("34404b"))
		estrado.draw_rect(Rect2(frente, Vector2(medida.x - 2, 1)), cor.lightened(0.24))
		for rebite in range(5, floori(medida.x - 4.0), 10):
			estrado.draw_rect(Rect2(frente + Vector2(rebite, 1), Vector2(1, 1)), Color("aeaa87"))
	)

func _registrar_cristal(no: Node2D, imagem: AnimatedSprite2D) -> void:
	var vista := RECEPTOR.new()
	no.add_child(vista)
	var pedra: Color = [Color("c9c4b3"), Color("acccd5"), Color("dfc4a3")][sala.fase_historia - 1]
	vista.montar(imagem.position, pedra)
	imagem.hide()
	var luz := _luz(no, imagem.position, Color("75cee2"), 0.1, 0.65)
	luz.color = vista.atualizar(imagem.animation, 0.0)
	cristais.append({"no": no, "imagem": imagem, "vista": vista, "luz": luz, "estado": imagem.animation})

func _adicionar_tochas(pontos: Array[Vector2]) -> void:
	var quadros := SpriteFrames.new()
	quadros.set_animation_speed("default", 7)
	for i in 6:
		var recorte := AtlasTexture.new()
		recorte.atlas = FOGO
		recorte.region = Rect2(88, i * 48, 44, 48)
		recorte.filter_clip = true
		quadros.add_frame("default", recorte)
	var ambiente := sala.get_node("AmbienteMasmorra")
	var locais_sonoros := PackedVector2Array()
	for i in pontos.size():
		var chama := AnimatedSprite2D.new()
		chama.sprite_frames = quadros
		chama.scale = Vector2.ONE * 0.55
		chama.position = to_local(decoracao.to_global(pontos[i]))
		add_child(chama)
		chama.play()
		chama.frame = i % 6
		var luz := _luz(self, chama.position + Vector2(0, 5), Color("ffb873"), 0.61, 1.38)
		luzes.append({"no": luz, "base": 0.61, "fase": i * 1.7})
		locais_sonoros.append(to_global(chama.position))
	ambiente.definir_tochas(locais_sonoros)

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
		registro.no.energy = registro.base * (1.0 + sin(tempo * 3.1 + registro.fase) * 0.075 + sin(tempo * 9.7 + registro.fase) * 0.04)
	for placa in placas:
		var alvo := 0.48 if placa.no.pressed else 0.12
		placa.luz.energy = move_toward(placa.luz.energy, alvo, delta * 2.0)
	for cristal in cristais:
		var estado: StringName = cristal.imagem.animation
		cristal.luz.color = cristal.vista.atualizar(estado, tempo + cristal.no.position.x * 0.022)
		cristal.luz.energy = (0.62 if estado in ["gold", "blue"] else 0.28) * (1.0 + sin(tempo * 2.6 + cristal.no.position.x * 0.1) * 0.14)
		if estado != cristal.estado:
			if estado in ["gold", "blue"]:
				var ponto := to_local(cristal.no.global_position)
				celebrar(ponto, &"acerto")
				_tocar(ponto, SOM_CRISTAL, -17.0, 1.08 if estado == &"gold" else 0.98)
			cristal.estado = estado
	for registro in herois:
		var heroi = registro.no
		var passo: float = heroi.global_position.distance_to(registro.anterior)
		registro.anterior = heroi.global_position
		registro.sombra.visible = not heroi.esta_morto and not heroi.caindo
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
	for i in range(ondas.size() - 1, -1, -1):
		ondas[i].tempo += delta
		if ondas[i].tempo >= 0.46:
			ondas.remove_at(i)
	faiscas_em -= delta
	if faiscas_em <= 0 and not luzes.is_empty() and particulas.size() < 96:
		faiscas_em = 0.10
		var registro: Dictionary = luzes[aleatorio.randi_range(0, luzes.size() - 1)]
		particulas.append({"p": to_local(registro.no.global_position) - Vector2(0, 10), "v": Vector2(aleatorio.randf_range(-6, 6), -14), "vida": 0.95, "total": 0.95, "cor": Color(1, 0.66, 0.31, 0.66), "tamanho": 1.0})
	queue_redraw()

func _draw() -> void:
	for onda in ondas:
		var variacao := clampf(onda.tempo / 0.46, 0, 1)
		var raio := lerpf(2.0, 9.0, variacao)
		var centro := Vector2(onda.ponto).round()
		var cor := Color(0.53, 0.76, 0.83, (1.0 - variacao) * 0.42)
		var pontos := PackedVector2Array()
		for i in 9:
			var deslocamento := Vector2.from_angle(float(i) * TAU / 8.0) * Vector2(raio, raio * 0.39)
			pontos.append(centro + deslocamento.round())
		draw_polyline(pontos, cor, 1.0)
	for particula in particulas:
		var cor: Color = particula.cor
		var gota: bool = particula.get("gota", false)
		if not gota:
			cor.a *= clampf(particula.vida / particula.total, 0, 1)
		var tamanho := Vector2(1, 3) if gota else Vector2.ONE * float(particula.tamanho)
		draw_rect(Rect2(Vector2(particula.p).round(), tamanho), cor)
