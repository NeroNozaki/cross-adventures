extends Control
class_name PauseMenu

const TEMA = preload("res://scripts/screens/tema_masmorra.gd")
const GUIA = preload("res://scripts/screens/guia_masmorra.gd")
const SONS = preload("res://scripts/screens/sons_menu.gd")
const CENA_INICIAL := "res://cenas/screens/start_menu.tscn"

@onready var _resume: Button = $VBoxContainer/resume

var _saindo := false
var _painel: Panel
var _guia: GUIA
var _som: SONS
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
	_painel.add_theme_stylebox_override("panel", TEMA.painel(12))
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
	TEMA.letra($VBoxContainer/label, 19)
	$VBoxContainer/label.add_theme_color_override("font_color", Color("f4d494"))
	_som = SONS.new()
	add_child(_som)
	var textos := {"resume": "Continuar", "controls": "Como jogar", "exit": "Sair do jogo", "menu": "Voltar ao início"}
	for botao in coluna.get_children():
		if not botao is Button:
			continue
		botao.text = textos[botao.name]
		TEMA.botao(botao, botao == _resume, 14, 30)
		_som.ligar(botao, &"" if botao.name == &"controls" else &"clique")
	$VBoxContainer/controls.pressed.connect(_mostrar_guia)

func _mostrar_guia() -> void:
	if is_instance_valid(_guia):
		return
	$VBoxContainer.hide()
	_painel.hide()
	_guia = GUIA.new()
	_guia.name = "Guia"
	_guia.fechar.connect(_fechar_guia)
	_guia.modulate.a = 0.72
	add_child(_guia)
	_guia.voltar.grab_focus()
	_som.ligar(_guia.voltar, &"")
	_som.tocar(&"abrir")
	_guia.create_tween().tween_property(_guia, "modulate:a", 1.0, 0.15)

func _fechar_guia() -> void:
	if _guia_solitario:
		queue_free()
		return
	if not is_instance_valid(_guia):
		return
	_guia.queue_free()
	_guia = null
	$VBoxContainer.show()
	_painel.show()
	$VBoxContainer/controls.grab_focus()
	_som.tocar(&"fechar")

func abrir_guia_solitario() -> void:
	_guia_solitario = true
	show()
	$VBoxContainer.hide()
	_painel.hide()
	_mostrar_guia()


func abrir() -> void:
	_saindo = false
	_definir_botoes_ativos(true)
	$VBoxContainer.show()
	_painel.show()
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
