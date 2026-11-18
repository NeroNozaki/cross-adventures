extends Control
class_name PauseMenu

const CENA_INICIAL := "res://cenas/screens/start_menu.tscn"

@onready var _resume: Button = $VBoxContainer/resume

var _saindo := false
var _painel: Panel
var _guia: PanelContainer
var _som: AudioStreamPlayer
var _guia_solitario := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_aplicar_visual()
	hide()

func _aplicar_visual() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color(0.015, 0.025, 0.04, 0.68)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	move_child(fundo, 0)
	_painel = Panel.new()
	_painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_painel.offset_left = -145
	_painel.offset_right = 145
	_painel.offset_top = -124
	_painel.offset_bottom = 124
	var moldura := StyleBoxTexture.new()
	moldura.texture = load("res://assets/Ninja Adventure - Asset Pack/Ui/Theme/Wip/ThemeMetal3/nine_path_panel.png")
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		moldura.set_texture_margin(lado, 5)
	_painel.add_theme_stylebox_override("panel", moldura)
	_painel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_painel)
	move_child(_painel, 1)
	var coluna := $VBoxContainer
	coluna.offset_left = -125
	coluna.offset_right = 125
	coluna.offset_top = -104
	coluna.offset_bottom = 104
	coluna.add_theme_constant_override("separation", 8)
	$VBoxContainer/label.text = "Pausa da aventura"
	$VBoxContainer/label.add_theme_font_size_override("font_size", 19)
	$VBoxContainer/label.add_theme_color_override("font_color", Color("f4d494"))
	_som = AudioStreamPlayer.new()
	_som.volume_db = -20
	add_child(_som)
	var textos := {"resume": "Continuar", "controls": "Como jogar", "exit": "Sair do jogo", "menu": "Voltar ao início"}
	for botao in coluna.get_children():
		if not botao is Button:
			continue
		botao.text = textos[botao.name]
		botao.custom_minimum_size.y = 30
		botao.add_theme_font_size_override("font_size", 14)
		for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
			var estilo := StyleBoxTexture.new()
			estilo.texture = load("res://assets/INTERFACE/botao_reliquia.svg")
			estilo.texture_margin_left = 15
			estilo.texture_margin_right = 15
			estilo.texture_margin_top = 5
			estilo.texture_margin_bottom = 5
			estilo.modulate_color = Color(1.17, 1.13, 1) if estado in ["hover", "focus"] else Color.WHITE
			botao.add_theme_stylebox_override(estado, estilo)
		botao.mouse_entered.connect(_som_ui.bind(false))
		botao.focus_entered.connect(_som_ui.bind(false))
		botao.button_down.connect(_som_ui.bind(true))
	$VBoxContainer/controls.pressed.connect(_mostrar_guia)

func _som_ui(clique: bool) -> void:
	if HistoriaDupla.silenciado:
		return
	_som.stream = load("res://assets/SONS/INTERFACE/CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg" if clique else "res://assets/SONS/INTERFACE/SELECAO/KENNEY_INTERFACE_SOUNDS/select_001.ogg")
	_som.play()

func _mostrar_guia() -> void:
	if is_instance_valid(_guia):
		return
	_guia = PanelContainer.new()
	_guia.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_guia.offset_left = -228
	_guia.offset_right = 228
	_guia.offset_top = -174
	_guia.offset_bottom = 174
	_guia.add_theme_stylebox_override("panel", _painel.get_theme_stylebox("panel"))
	add_child(_guia)
	var margem := MarginContainer.new()
	margem.add_theme_constant_override("margin_left", 20)
	margem.add_theme_constant_override("margin_right", 20)
	margem.add_theme_constant_override("margin_top", 18)
	margem.add_theme_constant_override("margin_bottom", 18)
	_guia.add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	margem.add_child(coluna)
	var titulo := Label.new()
	titulo.text = "Cada amigo tem um talento!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color("f4d494"))
	coluna.add_child(titulo)
	for dados in [["Nico", "player1_fixed", "W A S D ou analógico esquerdo: andar\nF / X azul: golpe · G / B vermelho: escudo"], ["Otto", "player2", "Setas: andar · Mouse: mirar\nClique esquerdo: disparar · Segure para carregar\nClique direito: dar um impulso"]]:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 16)
		coluna.add_child(linha)
		var retrato := TextureRect.new()
		var quadros: SpriteFrames = load("res://recursos/personagens/%s.tres" % dados[1])
		var quadro := quadros.get_frame_texture("idle_down", 0)
		var recorte := AtlasTexture.new()
		recorte.atlas = quadro
		recorte.region = quadro.get_image().get_used_rect()
		retrato.texture = recorte
		retrato.custom_minimum_size = Vector2(44, 54)
		retrato.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		linha.add_child(retrato)
		var comandos := VBoxContainer.new()
		comandos.add_theme_constant_override("separation", 6)
		linha.add_child(comandos)
		var texto := Label.new()
		texto.text = "%s\n%s" % [dados[0], dados[2]]
		texto.add_theme_font_size_override("font_size", 13)
		comandos.add_child(texto)
		var teclas := HBoxContainer.new()
		teclas.add_theme_constant_override("separation", 4)
		comandos.add_child(teclas)
		var arquivos := ["Keyboard/KeyW", "Keyboard/KeyA", "Keyboard/KeyS", "Keyboard/KeyD", "Keyboard/KeyF", "Keyboard/KeyG"] if dados[0] == "Nico" else ["Keyboard/KeyUp", "Keyboard/KeyDown", "Keyboard/KeyLeft", "Keyboard/KeyRight", "Mouse/MouseButtonLeft"]
		for arquivo in arquivos:
			var icone := TextureRect.new()
			icone.texture = load("res://assets/Ninja Adventure - Asset Pack/Ui/Input/%s.png" % arquivo)
			icone.custom_minimum_size = Vector2(18, 18)
			icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			teclas.add_child(icone)
		if dados[0] == "Nico":
			var alternativa := Label.new()
			alternativa.text = " ou "
			alternativa.add_theme_font_size_override("font_size",11)
			teclas.add_child(alternativa)
			for arquivo in ["JoystickLeft", "ButtonX/Idle", "ButtonB/Idle"]:
				var icone := TextureRect.new()
				icone.texture = load("res://assets/Ninja Adventure - Asset Pack/Ui/Input/Gamepad/%s.png" % arquivo)
				icone.custom_minimum_size = Vector2(22,22)
				icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				teclas.add_child(icone)
	var voltar := Button.new()
	voltar.text = "Entendi!"
	voltar.custom_minimum_size.y = 30
	voltar.add_theme_font_size_override("font_size", 14)
	for estado in ["normal", "hover", "focus", "pressed"]:
		voltar.add_theme_stylebox_override(estado, _resume.get_theme_stylebox(estado))
	voltar.pressed.connect(_fechar_guia)
	coluna.add_child(voltar)
	voltar.grab_focus()

func _fechar_guia() -> void:
	if _guia_solitario:
		queue_free()
		return
	if is_instance_valid(_guia):
		_guia.queue_free()
		_guia = null
	$VBoxContainer/controls.grab_focus()

func abrir_guia_solitario() -> void:
	_guia_solitario = true
	show()
	$VBoxContainer.hide()
	_painel.hide()
	_mostrar_guia()


func abrir() -> void:
	_saindo = false
	_definir_botoes_ativos(true)
	show()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.16)
	_resume.grab_focus()


func fechar() -> void:
	if _saindo:
		return
	_fechar_guia()
	hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _saindo:
		return
	if event.is_action_pressed("ajuda_fases") and not _guia_solitario:
		if is_instance_valid(_guia):
			fechar()
		else:
			_mostrar_guia()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pausar_jogo"):
		get_viewport().set_input_as_handled()
		if is_instance_valid(_guia):
			_fechar_guia()
		else:
			fechar()


func _on_resume_pressed() -> void:
	fechar()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_menu_pressed() -> void:
	if _saindo:
		return
	_saindo = true
	_definir_botoes_ativos(false)
	var fluxo: Node = get_node_or_null("/root/FluxoTela")
	if fluxo and fluxo.has_method("trocar"):
		fluxo.trocar(CENA_INICIAL)
	else:
		get_tree().paused = false
		get_tree().change_scene_to_file(CENA_INICIAL)


func _definir_botoes_ativos(ativo: bool) -> void:
	for filho in $VBoxContainer.get_children():
		if filho is Button:
			filho.disabled = not ativo
