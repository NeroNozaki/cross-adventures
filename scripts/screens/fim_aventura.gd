extends Control
## Conclusão animada; a criança pode ler com calma e escolher quando sair.
const ARTE = preload("res://assets/INTERFACE/entrada_masmorra.png")
const ATORES = preload("res://scripts/screens/celebracao_dupla.gd")
const MUSICA = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Musics/8 - End Theme.ogg")
const VITORIA = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Jingles/Success3.wav")
const PASSO = preload("res://assets/SONS/PASSOS/PEDRA_CONCRETO/KENNEY_IMPACT_SOUNDS/footstep_concrete_002.ogg")
const ESCRITA = preload("res://assets/SONS/INTERFACE/OUTROS/KENNEY_INTERFACE_SOUNDS/tick_001.ogg")
const CLIQUE = preload("res://assets/SONS/INTERFACE/CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg")
const SELECAO = preload("res://assets/SONS/INTERFACE/SELECAO/KENNEY_INTERFACE_SOUNDS/select_001.ogg")
const MOLDURA = preload("res://assets/INTERFACE/botao_reliquia.svg")
const MENSAGEM := "Cada ideia conta. Cada amigo importa.\nContinuem aprendendo, tentem de novo e ajudem uns aos outros.\nJuntos, vocês podem ir mais longe!"
var tempo := 0.0
var pronto := false
var saindo := false
var comemorou := false
var ultimo_passo := -1
var ultima_letra := -1
var fundo: TextureRect
var dupla: Node2D
var painel: PanelContainer
var texto: Label
var fim: Label
var botoes: HBoxContainer
var voltar: Button
var sair: Button
var pular: Button
var musica: AudioStreamPlayer
var jingle: AudioStreamPlayer
var passos: AudioStreamPlayer
var voz: AudioStreamPlayer
var som_ui: AudioStreamPlayer

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fundo = TextureRect.new()
	fundo.texture = ARTE
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	dupla = Node2D.new()
	dupla.name = "CelebracaoDupla"
	dupla.set_script(ATORES)
	add_child(dupla)
	_criar_mensagem()
	pular = _botao("Ver mensagem",_pular)
	pular.add_theme_font_size_override("font_size",12)
	pular.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pular.offset_left = -132
	pular.offset_right = -14
	pular.offset_top = 12
	pular.offset_bottom = 38
	musica = _audio(MUSICA.duplicate(),-32)
	(musica.stream as AudioStreamOggVorbis).loop = true
	musica.play()
	musica.stream_paused = HistoriaDupla.silenciado
	jingle = _audio(VITORIA,-20)
	passos = _audio(PASSO,-25)
	voz = _audio(ESCRITA,-32)
	som_ui = _audio(SELECAO,-18)
	pular.grab_focus()
	_atualizar(0)

func _criar_mensagem() -> void:
	painel = PanelContainer.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	painel.offset_top = 24
	painel.offset_bottom = 166
	var estilo := StyleBoxTexture.new()
	estilo.texture = load("res://assets/Ninja Adventure - Asset Pack/Ui/Theme/Wip/ThemeMetal3/nine_path_panel.png")
	for lado in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		estilo.set_texture_margin(lado,5)
		estilo.set_content_margin(lado,12)
	painel.add_theme_stylebox_override("panel",estilo)
	add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation",8)
	painel.add_child(coluna)
	var titulo := Label.new()
	titulo.text = "Vocês conseguiram!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size",24)
	titulo.add_theme_color_override("font_color",Color("ffdb91"))
	coluna.add_child(titulo)
	texto = Label.new()
	texto.text = MENSAGEM
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_size_override("font_size",14)
	texto.visible_characters = 0
	coluna.add_child(texto)
	fim = Label.new()
	fim.text = "FIM DA AVENTURA"
	fim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fim.add_theme_font_size_override("font_size",15)
	fim.add_theme_color_override("font_color",Color("ffdc96"))
	fim.add_theme_color_override("font_shadow_color",Color("13232b"))
	fim.add_theme_constant_override("shadow_offset_y",2)
	fim.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	fim.offset_left = -180
	fim.offset_right = 180
	fim.offset_top = -84
	fim.offset_bottom = -60
	add_child(fim)
	botoes = HBoxContainer.new()
	botoes.add_theme_constant_override("separation",12)
	botoes.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	botoes.offset_left = -200
	botoes.offset_right = 200
	botoes.offset_top = -52
	botoes.offset_bottom = -18
	add_child(botoes)
	voltar = _botao("Voltar ao início",_voltar)
	sair = _botao("Sair do jogo",_sair)
	for botao in [voltar,sair]:
		botao.get_parent().remove_child(botao)
		botoes.add_child(botao)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		botao.disabled = true
	botoes.hide()
	painel.modulate.a = 0
	fim.modulate.a = 0

func _botao(rotulo: String, acao: Callable) -> Button:
	var botao := Button.new()
	botao.text = rotulo
	botao.add_theme_font_size_override("font_size",14)
	for estado in ["normal","hover","pressed","focus","disabled"]:
		var estilo := StyleBoxTexture.new()
		estilo.texture = MOLDURA
		estilo.texture_margin_left = 15
		estilo.texture_margin_right = 15
		estilo.texture_margin_top = 5
		estilo.texture_margin_bottom = 5
		estilo.set_content_margin_all(8)
		estilo.modulate_color = Color(1.2,1.15,1) if estado in ["hover","focus"] else Color.WHITE
		botao.add_theme_stylebox_override(estado,estilo)
	botao.mouse_entered.connect(func(): _som(SELECAO))
	botao.focus_entered.connect(func(): _som(SELECAO))
	botao.pressed.connect(func(): _som(CLIQUE); acao.call())
	add_child(botao)
	return botao

func _audio(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = volume
	add_child(audio)
	return audio

func _som(stream: AudioStream) -> void:
	if is_instance_valid(som_ui) and not HistoriaDupla.silenciado:
		som_ui.stream = stream
		som_ui.play()

func _retangulo_arte() -> Rect2:
	var escala := maxf(size.x/ARTE.get_width(),size.y/ARTE.get_height())*1.025
	var dimensao := ARTE.get_size()*escala
	return Rect2((size-dimensao)*0.5+Vector2(sin(tempo*0.15)*1.2,0),dimensao)

func _process(delta: float) -> void:
	if FluxoTela.em_transicao:
		return
	tempo += delta
	_atualizar(delta)

func _atualizar(delta: float) -> void:
	var arte := _retangulo_arte()
	fundo.position = arte.position
	fundo.size = arte.size
	dupla.atualizar(tempo,delta,arte)
	var largura := minf(490,size.x-28)
	painel.offset_left = -largura*0.5
	painel.offset_right = largura*0.5
	painel.modulate.a = smoothstep(6.2,6.7,tempo)
	pular.visible = tempo < 6.2
	fim.modulate.a = smoothstep(6.5,7.0,tempo)
	var letras := clampi(int((tempo-6.3)*28),0,MENSAGEM.length())
	texto.visible_characters = letras
	if letras > ultima_letra and letras > 0 and letras%3 == 0 and not HistoriaDupla.silenciado:
		voz.play()
	ultima_letra = letras
	if tempo >= 3.5 and not comemorou:
		comemorou = true
		if not HistoriaDupla.silenciado:
			jingle.play()
	var passo := int(tempo*3.5)
	if tempo > 0.5 and tempo < 3.45 and passo != ultimo_passo and not HistoriaDupla.silenciado:
		passos.pitch_scale = 0.94+float(passo%3)*0.04
		passos.play()
	ultimo_passo = passo
	if letras == MENSAGEM.length() and not pronto:
		pronto = true
		botoes.show()
		for botao in [voltar,sair]:
			botao.disabled = false
		voltar.grab_focus()
	_sincronizar_audio()
	if not saindo:
		musica.volume_db = lerpf(musica.volume_db,-29.0 if jingle.playing else -24.0,minf(1,delta*2))

func _sincronizar_audio() -> void:
	for audio in [musica,jingle,passos,voz,som_ui]:
		audio.stream_paused = HistoriaDupla.silenciado

func _pular() -> void:
	tempo = maxf(tempo,6.4+MENSAGEM.length()/28.0)
	_atualizar(0)

func _voltar() -> void:
	if saindo:
		return
	saindo = true
	voltar.disabled = true
	sair.disabled = true
	FluxoTela.trocar("res://cenas/screens/start_menu.tscn")

func _sair() -> void:
	if saindo:
		return
	saindo = true
	voltar.disabled = true
	sair.disabled = true
	var fade := create_tween().set_parallel(true)
	fade.tween_property(self,"modulate:a",0,0.28)
	fade.tween_property(musica,"volume_db",-55,0.28)
	await fade.finished
	set_process(false)
	_parar_audio()
	# O mixer libera os playbacks no próximo ciclo antes de fechar o processo.
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("alternar_audio"):
		HistoriaDupla.silenciado = not HistoriaDupla.silenciado
		_sincronizar_audio()
		get_viewport().set_input_as_handled()

func _parar_audio() -> void:
	for no in get_children():
		if no is AudioStreamPlayer:
			no.stop()
			no.stream = null

func _exit_tree() -> void:
	_parar_audio()
