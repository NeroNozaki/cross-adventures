extends Control
## Pequena cena animada de convite, antes da história de despertar nas celas.
const ARTE = preload("res://assets/INTERFACE/entrada_masmorra.png")
const NICO = preload("res://recursos/personagens/player1_fixed.tres")
const OTTO = preload("res://recursos/personagens/player2.tres")
const CAPA = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Character/Skeleton/SeparateAnim/NicoCape.svg")
const MUSICA = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Musics/1 - Adventure Begin.ogg")
const PASSO = preload("res://assets/SONS/PASSOS/PEDRA_CONCRETO/KENNEY_IMPACT_SOUNDS/footstep_concrete_002.ogg")
const CLIQUE = preload("res://assets/SONS/INTERFACE/CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg")
const SELECAO = preload("res://assets/SONS/INTERFACE/SELECAO/KENNEY_INTERFACE_SOUNDS/select_001.ogg")
const ESCRITA = preload("res://assets/SONS/INTERFACE/OUTROS/KENNEY_INTERFACE_SOUNDS/tick_001.ogg")
const MOLDURA = preload("res://assets/INTERFACE/botao_reliquia.svg")
const CHAMADA := "Preparados para esta aventura?"
var tempo := 0.0
var tempo_saida := -1.0
var partindo := false
var concluida := false
var destino := "res://cenas/areas/area_1.tscn"
var dupla: Array[AnimatedSprite2D] = []
var capa: Sprite2D
var fundo: TextureRect
var luzes: Node2D
var sombras: Node2D
var chamada: Label
var convite: Label
var seguir: Button
var pular: Button
var musica: AudioStreamPlayer
var passos: AudioStreamPlayer
var voz: AudioStreamPlayer
var interface_som: AudioStreamPlayer
var ultimo_passo := -1
var ultima_letra := -1
var origens: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if get_tree().has_meta("destino_abertura"):
		destino = str(get_tree().get_meta("destino_abertura"))
		get_tree().remove_meta("destino_abertura")
	fundo = TextureRect.new()
	fundo.texture = ARTE
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	luzes = Node2D.new()
	luzes.draw.connect(_desenhar_luzes)
	add_child(luzes)
	sombras = Node2D.new()
	sombras.draw.connect(_desenhar_sombras)
	add_child(sombras)
	_criar_personagem(NICO)
	_criar_personagem(OTTO)
	capa = Sprite2D.new()
	capa.texture = CAPA
	capa.z_index = -1
	capa.position = Vector2(0, -1)
	dupla[0].add_child(capa)
	chamada = _texto(CHAMADA, 24, Color("ffdc94"))
	chamada.position.y = 32
	chamada.visible_characters = 0
	convite = _texto("Quatro desafios e muitos segredos.\nAjudem Nico e Otto a encontrar a saída!", 14, Color("f7f2df"))
	convite.position.y = 75
	convite.modulate.a = 0
	seguir = _botao("Vamos juntos!", _entrar)
	seguir.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	seguir.offset_left = -103
	seguir.offset_right = 103
	seguir.offset_top = -58
	seguir.offset_bottom = -22
	seguir.disabled = true
	seguir.modulate.a = 0
	pular = _botao("Pular abertura", _finalizar)
	pular.add_theme_font_size_override("font_size", 12)
	pular.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pular.offset_left = -126
	pular.offset_right = -14
	pular.offset_top = 12
	pular.offset_bottom = 38
	musica = _audio(MUSICA, -24)
	musica.finished.connect(musica.play)
	musica.play()
	passos = _audio(PASSO, -24)
	voz = _audio(ESCRITA, -30)
	interface_som = _audio(SELECAO, -18)
	pular.grab_focus()
	_atualizar_cena()

func _texto(conteudo: String, tamanho: int, cor: Color) -> Label:
	var label := Label.new()
	label.text = conteudo
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_shadow_color", Color(0.015, 0.04, 0.06, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _botao(rotulo: String, acao: Callable) -> Button:
	var botao := Button.new()
	botao.text = rotulo
	botao.add_theme_font_size_override("font_size", 16)
	for estado in ["normal", "hover", "focus", "pressed", "disabled"]:
		var estilo := StyleBoxTexture.new()
		estilo.texture = MOLDURA
		estilo.texture_margin_left = 15
		estilo.texture_margin_right = 15
		estilo.texture_margin_top = 5
		estilo.texture_margin_bottom = 5
		estilo.set_content_margin_all(8)
		estilo.modulate_color = Color(1.2, 1.15, 1) if estado in ["hover", "focus"] else Color.WHITE
		botao.add_theme_stylebox_override(estado, estilo)
	botao.mouse_entered.connect(func(): _som_ui(SELECAO))
	botao.focus_entered.connect(func(): _som_ui(SELECAO))
	botao.pressed.connect(func(): _som_ui(CLIQUE); acao.call())
	add_child(botao)
	return botao

func _audio(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume
	add_child(audio)
	return audio

func _som_ui(stream: AudioStream) -> void:
	if is_instance_valid(interface_som) and not HistoriaDupla.silenciado:
		interface_som.stream = stream
		interface_som.play()

func _criar_personagem(quadros: SpriteFrames) -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = quadros
	sprite.play("walk_right")
	# A origem fica nos pés, independente das margens de cada spritesheet.
	sprite.centered = false
	add_child(sprite)
	dupla.append(sprite)

func _retangulo_arte() -> Rect2:
	var escala := maxf(size.x / ARTE.get_width(), size.y / ARTE.get_height()) * 1.025
	var dimensao := ARTE.get_size() * escala
	return Rect2((size - dimensao) * 0.5 + Vector2(sin(tempo * 0.18) * 1.5, 0), dimensao)

func _posicao_heroi(indice: int) -> Vector2:
	var chegada := smoothstep(0.0, 4.0, tempo)
	var x := lerpf(-0.06 - indice * 0.07, 0.42 + indice * 0.085, chegada)
	var y := 0.697
	if partindo:
		var progresso := clampf((tempo - tempo_saida - indice * 0.22) / 3.2, 0, 1)
		x = lerpf(0.42 + indice * 0.085, 0.79, smoothstep(0, 1, progresso))
		y = lerpf(0.697, 0.667, smoothstep(0.75, 1.0, progresso))
	var arte := _retangulo_arte()
	return (arte.position + Vector2(x, y) * arte.size).round()

func _process(delta: float) -> void:
	# A cortina termina antes de começar a caminhada e a escrita.
	if FluxoTela.em_transicao:
		return
	tempo += delta
	_atualizar_cena()
	var letras := clampi(int((tempo - 0.45) * 23.0), 0, CHAMADA.length())
	chamada.visible_characters = letras
	if letras != ultima_letra and letras > 0 and letras % 2 == 0 and not HistoriaDupla.silenciado:
		voz.pitch_scale = 0.95 + (letras % 3) * 0.05
		voz.play()
	ultima_letra = letras
	convite.modulate.a = smoothstep(1.8, 2.5, tempo)
	if tempo >= 4 and not partindo:
		seguir.modulate.a = smoothstep(4, 4.5, tempo)
		if seguir.disabled:
			seguir.disabled = false
			seguir.grab_focus()
	var andando := tempo < 4.0 or partindo
	var passo := int(tempo * 3.5)
	if andando and passo != ultimo_passo and not HistoriaDupla.silenciado:
		passos.pitch_scale = 0.9 + float(passo % 3) * 0.08
		passos.play()
	ultimo_passo = passo
	musica.stream_paused = HistoriaDupla.silenciado
	if partindo and tempo - tempo_saida > 3.8:
		_finalizar()

func _atualizar_cena() -> void:
	var arte := _retangulo_arte()
	fundo.position = arte.position
	fundo.size = arte.size
	for label in [chamada, convite]:
		label.position.x = maxf(14, size.x * 0.5 - 280)
		label.size.x = minf(560, size.x - 28)
	for i in dupla.size():
		var heroi := dupla[i]
		var andando := tempo < 4 or partindo
		var animacao := "walk_right" if andando else ("idle_right" if i == 0 else "idle_left")
		if heroi.animation != animacao:
			heroi.play(animacao)
		var chave := str(i) + animacao
		if not origens.has(chave):
			var largura := 0.0
			var base := 0.0
			for quadro in heroi.sprite_frames.get_frame_count(heroi.animation):
				var textura := heroi.sprite_frames.get_frame_texture(heroi.animation, quadro)
				largura = textura.get_width() * 0.5
				base = maxf(base, textura.get_image().get_used_rect().end.y)
			origens[chave] = Vector2(largura, base)
		var fator := (arte.size.y * 0.12) / 16.0 if i == 0 else (arte.size.y * 0.12) / 32.0
		heroi.scale = Vector2(fator * (0.9 if i == 0 else 1.0), fator)
		heroi.offset = -origens[chave]
		heroi.position = _posicao_heroi(i)
		heroi.modulate.a = 1.0 - smoothstep(2.7 + i * 0.22, 3.3 + i * 0.22, tempo - tempo_saida) if partindo else 1.0
	capa.position = dupla[0].offset + Vector2(4, 9)
	capa.rotation = sin(tempo * 7) * (0.07 if tempo < 4 or partindo else 0.025)
	luzes.queue_redraw()
	sombras.queue_redraw()

func _desenhar_luzes() -> void:
	var arte := _retangulo_arte()
	for ponto in [Vector2(0.622, 0.46), Vector2(0.922, 0.46), Vector2(0.79, 0.60)]:
		for raio in [12, 23, 36]:
			luzes.draw_circle(arte.position + ponto * arte.size, raio + sin(tempo * 5) * 1.2, Color(1, 0.64, 0.2, 0.025))
	for i in 36:
		var x := fposmod(i * 0.179 + sin(tempo * 0.3 + i) * 0.02, 1.0)
		var y := fposmod(i * 0.237 - tempo * 0.013, 0.74)
		var ponto := arte.position + Vector2(x, y) * arte.size
		luzes.draw_rect(Rect2(ponto.round(), Vector2(1.5, 1.5)), Color(1, 0.85, 0.4, 0.2 + sin(tempo * 2 + i) * 0.18))

func _desenhar_sombras() -> void:
	for i in dupla.size():
		var pos := _posicao_heroi(i)
		sombras.draw_set_transform(pos, 0, Vector2(1, 0.24))
		sombras.draw_circle(Vector2.ZERO, 16, Color(0.01, 0.025, 0.035, dupla[i].modulate.a * 0.5))
		sombras.draw_set_transform(Vector2.ZERO)

func _entrar() -> void:
	if partindo or concluida:
		return
	partindo = true
	tempo_saida = tempo
	seguir.disabled = true
	create_tween().tween_property(seguir, "modulate:a", 0.0, 0.3)
	convite.text = "Vamos descobrir juntos!"

func _finalizar() -> void:
	if concluida:
		return
	concluida = true
	seguir.disabled = true
	pular.disabled = true
	create_tween().tween_property(musica, "volume_db", -50, 0.25)
	FluxoTela.trocar(destino)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("alternar_audio"):
		HistoriaDupla.silenciado = not HistoriaDupla.silenciado
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_finalizar()
		get_viewport().set_input_as_handled()
