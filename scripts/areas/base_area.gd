extends Node2D
class_name BaseArea

@onready var player1 = $Personagens/Player1
@onready var player2 = $Personagens/Player2

const CENA_PAUSA: PackedScene = preload("res://cenas/screens/pause_menu.tscn")

var _pause_menu: Control

func _ready() -> void:
	var camada := CanvasLayer.new()
	camada.name = "CamadaPausa"
	camada.layer = 90
	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada)
	_pause_menu = CENA_PAUSA.instantiate()
	camada.add_child(_pause_menu)

func _process(_delta: float) -> void:
	if has_node("Personagens/Player1/Marcador") and player1:
		var marcador1 = $Personagens/Player1/MarcadorPlayer1
		marcador1.position = player1.position + Vector2(0, 8)
		marcador1.visible = not player1.esta_morto

	if has_node("Personagens/Player2/Marcador") and player2:
		var marcador2 = $Personagens/Player2/MarcadorPlayer2
		marcador2.position = player2.position + Vector2(0, 8)
		marcador2.visible = not player2.esta_morto

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
