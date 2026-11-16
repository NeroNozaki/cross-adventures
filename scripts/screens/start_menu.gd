extends Control
@export_file("*.tscn") var proxima_cena := "res://cenas/areas/puzzle_01.tscn"
var fundo: TextureRect
var titulo: TextureRect
var menu: VBoxContainer
var som: AudioStreamPlayer
var musica: AudioStreamPlayer
var tempo := 0.0
var saindo := false
var mudo := false
var efeitos: Node2D

func _ready() -> void:
	mudo = HistoriaDupla.silenciado
	fundo = TextureRect.new()
	fundo.texture = load("res://assets/INTERFACE/capa_nico_otto.png")
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	efeitos = Node2D.new()
	efeitos.draw.connect(_desenhar_particulas)
	add_child(efeitos)
	titulo = TextureRect.new()
	titulo.texture = load("res://assets/INTERFACE/letreiro.png")
	titulo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	titulo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	titulo.offset_left = -155
	titulo.offset_right = 155
	titulo.offset_top = 8
	titulo.offset_bottom = 108
	add_child(titulo)
	menu = VBoxContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	menu.offset_left = -95
	menu.offset_right = 95
	menu.offset_top = -116
	menu.offset_bottom = -12
	menu.add_theme_constant_override("separation",5)
	add_child(menu)
	for item in [["Jogar",_on_play_pressed],["Como jogar",_ajuda],["Sair",_on_exit_pressed]]:
		var b := botao(item[0])
		b.pressed.connect(item[1])
		menu.add_child(b)
	som = AudioStreamPlayer.new()
	add_child(som)
	musica = AudioStreamPlayer.new()
	musica.stream = load("res://assets/Ninja Adventure - Asset Pack/Audio/Musics/21 - Dungeon.ogg")
	musica.set("parameters/looping",1)
	musica.volume_db = -35
	add_child(musica)
	musica.play()
	musica.stream_paused = mudo
	create_tween().tween_property(musica,"volume_db",-23,1.2)
	menu.get_child(0).grab_focus()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func botao(texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size.y = 30
	b.add_theme_font_size_override("font_size",14)
	for estado in ["normal","hover","focus","pressed"]:
		var estilo := StyleBoxTexture.new()
		estilo.texture = load("res://assets/INTERFACE/botao_reliquia.svg")
		estilo.texture_margin_left = 15
		estilo.texture_margin_right = 15
		estilo.texture_margin_top = 5
		estilo.texture_margin_bottom = 5
		estilo.content_margin_left = 18
		estilo.content_margin_right = 18
		estilo.modulate_color = Color(1.2,1.15,1) if estado in ["hover","focus"] else Color.WHITE
		b.add_theme_stylebox_override(estado,estilo)
	b.mouse_entered.connect(_som.bind(false))
	b.focus_entered.connect(_som.bind(false))
	b.button_down.connect(_som.bind(true))
	return b

func _som(clique: bool) -> void:
	if mudo:
		return
	som.stream = load("res://assets/SONS/INTERFACE/CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg" if clique else "res://assets/SONS/INTERFACE/SELECAO/KENNEY_INTERFACE_SOUNDS/select_001.ogg")
	som.volume_db = -17
	som.play()

func _process(delta: float) -> void:
	tempo += delta
	# Movimento de câmera discreto, sem deformar rostos ou sprites.
	fundo.position = Vector2(-5+sin(tempo*0.16)*3,-4+cos(tempo*0.21)*2)
	fundo.size = size+Vector2(12,10)
	fundo.modulate = Color(1.0+sin(tempo*2.3)*0.012,1.0,1.0)
	titulo.modulate = Color(1.0,1.0,1.0,0.96+sin(tempo*1.5)*0.04)
	efeitos.queue_redraw()

func _desenhar_particulas() -> void:
	# Pequenas partículas animadas, independentes da ilustração.
	for i in 24:
		var x := fmod(i*0.618+sin(tempo*0.1+i)*0.01,1.0)*size.x
		var y := (1.0-fmod(tempo*0.018+i*0.137,1.0))*size.y
		var alfa := (0.15+sin(tempo*1.4+i)*0.1)
		efeitos.draw_rect(Rect2(Vector2(x,y).round(),Vector2(1,1)),Color(1,0.8,0.4,alfa))
	for ponto in [Vector2(0.10,0.36),Vector2(0.90,0.36),Vector2(0.43,0.43),Vector2(0.56,0.43)]:
		var cor := Color(1,0.65,0.12,0.02+sin(tempo*4+ponto.x*20)*0.008)
		efeitos.draw_circle(ponto*size,18,cor)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("alternar_audio"):
		mudo = not mudo
		HistoriaDupla.silenciado = mudo
		musica.stream_paused = mudo

func _on_play_pressed() -> void:
	if saindo:
		return
	saindo = true
	HistoriaDupla.nova_partida()
	for b in menu.get_children():
		b.disabled = true
	create_tween().tween_property(musica,"volume_db",-45,0.35)
	var abertura: PackedScene = load("res://cenas/screens/entrada_aventura.tscn")
	# A cena de abertura recebe o destino configurado neste menu.
	get_tree().set_meta("destino_abertura", proxima_cena)
	FluxoTela.trocar(abertura.resource_path)

func _ajuda() -> void:
	if has_node("GuiaControles"):
		return
	var guia := load("res://cenas/screens/pause_menu.tscn").instantiate() as Control
	guia.name = "GuiaControles"
	add_child(guia)
	guia.tree_exited.connect(func(): menu.get_child(1).grab_focus())
	guia.abrir_guia_solitario()

func _on_exit_pressed() -> void:
	get_tree().quit()
	
	
