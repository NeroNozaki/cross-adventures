extends Node2D
class_name BaseArea

const CENA_PAUSA: PackedScene = preload("res://cenas/screens/pause_menu.tscn")
const AMBIENTE = preload("res://scripts/audio/ambiente_masmorra.gd")
## Capítulo narrativo desta sala; configurar 1..4 nas futuras fases.
@export_range(1,4) var fase_historia: int = 1

var _pause_menu: Control


func _ready() -> void:
	var ambiente := Node2D.new()
	ambiente.name = "AmbienteMasmorra"
	ambiente.set_script(AMBIENTE)
	add_child(ambiente)
	var camada := CanvasLayer.new()
	camada.name = "CamadaPausa"
	camada.layer = 90
	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada)
	_pause_menu = CENA_PAUSA.instantiate()
	camada.add_child(_pause_menu)
	HistoriaDupla.iniciar_fase.call_deferred(fase_historia)


func _unhandled_input(event: InputEvent) -> void:
	if _pause_menu == null or _pause_menu.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		pausar()
		get_viewport().set_input_as_handled()


func pausar() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	if _pause_menu.has_method("abrir"):
		_pause_menu.abrir()


func esta_pausado() -> bool:
	return _pause_menu != null and _pause_menu.visible
