extends Control
class_name PauseMenu

const CENA_INICIAL := "res://cenas/screens/start_menu.tscn"

@onready var _resume: Button = $VBoxContainer/resume

var _saindo := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBoxContainer/controls.pressed.connect(Convivencia.abrir_ajuda)
	hide()


func abrir() -> void:
	_saindo = false
	_definir_botoes_ativos(true)
	show()
	_resume.grab_focus()


func fechar() -> void:
	if _saindo:
		return
	hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _saindo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
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
