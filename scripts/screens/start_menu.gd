extends Control

@export_file("*.tscn") var proxima_cena := "res://cenas/areas/area_1.tscn"
const TEMA = preload("res://scripts/screens/tema_masmorra.gd")
const SONS = preload("res://scripts/screens/sons_menu.gd")
const PAUSA = preload("res://cenas/screens/pause_menu.tscn")
const CAPA = preload("res://assets/INTERFACE/capa_nico_otto.png")
const TITULO = preload("res://assets/INTERFACE/letreiro.png")
const TRILHA = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Musics/21 - Dungeon.ogg")
const GOTA = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Sounds/Elemental/WaterDrop.wav")
const ABERTURA := "res://cenas/screens/entrada_aventura.tscn"

var fundo: TextureRect
var titulo: TextureRect
var menu: VBoxContainer
var som: SONS
var musica: AudioStreamPlayer
var gotas: AudioStreamPlayer
var som_botao: Button
var efeitos: Node2D
var recorte_capa := Rect2()
var tempo := 0.0
var gota_em := 3.0
var saindo := false

func _ready() -> void:
	fundo = TextureRect.new()
	fundo.texture = CAPA
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fundo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var luz := ShaderMaterial.new()
	luz.shader = preload("res://recursos/capa_masmorra.gdshader")
	fundo.material = luz
	add_child(fundo)

	efeitos = Node2D.new()
	efeitos.draw.connect(_desenhar_particulas)
	add_child(efeitos)
	resized.connect(_enquadrar_capa)
	_enquadrar_capa()

	titulo = TextureRect.new()
	titulo.texture = TITULO
	titulo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	titulo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	titulo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	titulo.offset_left = -165
	titulo.offset_right = 165
	titulo.offset_top = 10
	titulo.offset_bottom = 126
	add_child(titulo)
	move_child(efeitos, titulo.get_index())

	som = SONS.new()
	add_child(som)
	menu = VBoxContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	menu.offset_left = -94
	menu.offset_right = 94
	menu.offset_top = -124
	menu.offset_bottom = -18
	menu.add_theme_constant_override("separation", 5)
	add_child(menu)
	for item in [
		["Jogar", _on_play_pressed, &"jogar"],
		["Como jogar", _ajuda, &""],
		["Sair", _on_exit_pressed, &"clique"]
	]:
		var controle := Button.new()
		controle.text = item[0]
		var destaque: bool = item[0] == "Jogar"
		TEMA.botao(controle, destaque, 16 if destaque else 13, 36 if destaque else 29)
		if destaque:
			var normal := controle.get_theme_stylebox("normal") as StyleBoxTexture
			normal.modulate_color = Color(1.16, 1.06, 0.94)
		controle.pressed.connect(item[1])
		som.ligar(controle, item[2])
		menu.add_child(controle)

	som_botao = Button.new()
	som_botao.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	som_botao.offset_left = -117
	som_botao.offset_top = -41
	som_botao.offset_right = -10
	som_botao.offset_bottom = -12
	TEMA.botao(som_botao, false, 10, 24)
	som_botao.pressed.connect(_alternar_som)
	som.ligar(som_botao, &"")
	add_child(som_botao)

	musica = AudioStreamPlayer.new()
	musica.stream = TRILHA.duplicate()
	(musica.stream as AudioStreamOggVorbis).loop = true
	musica.volume_db = -38
	add_child(musica)
	musica.play()
	gotas = AudioStreamPlayer.new()
	gotas.stream = GOTA
	gotas.volume_db = -35
	add_child(gotas)
	_atualizar_som()
	create_tween().tween_property(musica, "volume_db", -23, 1.0)
	menu.get_child(0).grab_focus()

func _enquadrar_capa() -> void:
	var proporcao := CAPA.get_size()
	var escala := maxf(size.x / proporcao.x, size.y / proporcao.y)
	var desenho := proporcao * escala
	recorte_capa = Rect2((size - desenho) * 0.5, desenho)

func _process(delta: float) -> void:
	tempo += delta
	efeitos.queue_redraw()
	gota_em -= delta
	if gota_em > 0:
		return
	gota_em = randf_range(4.5, 8.0)
	if not HistoriaDupla.silenciado and not saindo:
		gotas.pitch_scale = randf_range(0.78, 1.0)
		gotas.play()

func _desenhar_particulas() -> void:
	_desenhar_brilho_letreiro()
	for i in 22:
		var origem := 0.15 if i % 2 == 0 else 0.86
		var altura := fposmod(tempo * (0.024 + i * 0.001) + i * 0.039, 0.16)
		var x := origem + sin(i * 7.1) * 0.035 + sin(tempo * 1.1 + i) * 0.011
		var ponto := recorte_capa.position + Vector2(x, 0.39 - altura) * recorte_capa.size
		var alfa := sin(altura * PI / 0.16) * (0.25 + sin(i * 2.2) * 0.12)
		efeitos.draw_rect(Rect2(ponto.round(), Vector2.ONE), Color(1, 0.71, 0.34, alfa))
	for i in 11:
		var altura := fposmod(tempo * (0.022 + i * 0.001) + i * 0.091, 0.17)
		var x := 0.50 + (i - 5) * 0.006 + sin(tempo * 1.3 + i) * 0.009
		var ponto := recorte_capa.position + Vector2(x, 0.58 - altura) * recorte_capa.size
		efeitos.draw_rect(Rect2(ponto.round(), Vector2.ONE), Color(0.42, 0.91, 1.0, sin(altura * PI / 0.17) * 0.5))

func _desenhar_brilho_letreiro() -> void:
	var ciclo := fposmod(tempo, 4.5)
	if not titulo.visible or ciclo >= 0.72:
		return
	var alfa := sin(ciclo * PI / 0.72)
	var escala := minf(titulo.size.x / TITULO.get_width(), titulo.size.y / TITULO.get_height())
	var medidas := TITULO.get_size() * escala
	var origem := titulo.position + (titulo.size - medidas) * 0.5
	var centro := (origem + Vector2(0.509, 0.307) * medidas).round()
	var tamanho := 1.0 + 4.0 * alfa
	var cor := Color(0.68, 0.98, 1.0, alfa * 0.78)
	efeitos.draw_line(centro - Vector2(tamanho, 0), centro + Vector2(tamanho, 0), cor, 1.0)
	efeitos.draw_line(centro - Vector2(0, tamanho + 1), centro + Vector2(0, tamanho + 1), cor, 1.0)
	efeitos.draw_rect(Rect2(centro - Vector2.ONE, Vector2(2, 2)), Color(0.94, 1.0, 1.0, alfa))

func _atualizar_som() -> void:
	var silenciado: bool = HistoriaDupla.silenciado
	som_botao.text = "M · Som desligado" if silenciado else "M · Som ligado"
	musica.stream_paused = silenciado
	if silenciado:
		gotas.stop()
		som.stop()

func _alternar_som() -> void:
	HistoriaDupla.silenciado = not HistoriaDupla.silenciado
	_atualizar_som()
	som.tocar(&"clique")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("alternar_audio") and not event.is_echo():
		_alternar_som()
		get_viewport().set_input_as_handled()

func _on_play_pressed() -> void:
	if saindo:
		return
	saindo = true
	HistoriaDupla.nova_partida()
	for controle in menu.get_children():
		controle.disabled = true
	som_botao.disabled = true
	create_tween().tween_property(musica, "volume_db", -45, 0.28)
	get_tree().set_meta("destino_abertura", proxima_cena)
	FluxoTela.trocar(ABERTURA)

func _ajuda() -> void:
	if saindo or has_node("GuiaControles"):
		return
	var guia := PAUSA.instantiate()
	guia.name = "GuiaControles"
	add_child(guia)
	guia.tree_exited.connect(_restaurar_foco)
	menu.hide()
	som_botao.hide()
	titulo.hide()
	guia.abrir_guia_solitario()

func _restaurar_foco() -> void:
	var como_jogar := menu.get_child(1) as Button
	if como_jogar.is_inside_tree() and not is_queued_for_deletion():
		menu.show()
		som_botao.show()
		titulo.show()
		como_jogar.grab_focus()
		som.tocar(&"fechar")

func _on_exit_pressed() -> void:
	get_tree().quit()
