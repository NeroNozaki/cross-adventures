extends Node2D
class_name BaseArea

const CENA_PAUSA: PackedScene = preload("res://cenas/screens/pause_menu.tscn")
const AMBIENTE = preload("res://scripts/audio/ambiente_masmorra.gd")
const ACABAMENTO = preload("res://scripts/areas/acabamento_masmorra.gd")
const HUD = preload("res://scripts/areas/hud_campanha.gd")
@export_range(1,3) var fase_historia: int = 1

var _pause_menu: Control


func _ready() -> void:
	var ambiente := Node2D.new()
	ambiente.name = "AmbienteMasmorra"
	ambiente.set_script(AMBIENTE)
	add_child(ambiente)
	var acabamento := Node2D.new()
	acabamento.name = "AcabamentoMasmorra"
	acabamento.set_script(ACABAMENTO)
	add_child(acabamento)
	var camada := CanvasLayer.new()
	camada.name = "CamadaPausa"
	camada.layer = 90
	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada)
	_pause_menu = CENA_PAUSA.instantiate()
	camada.add_child(_pause_menu)
	var hud := HUD.new()
	hud.name = "HUDCampanha"
	add_child(hud)
	var camera := get_node_or_null("Personagens/Camera2D")
	var campo := get_node_or_null("HoleField") as HoleField
	if camera and campo and campo.tile_map_layer:
		camera.configurar_enquadramento(campo.tile_map_layer)
	_iniciar_historia.call_deferred()


func _iniciar_historia() -> void:
	if get_tree().current_scene == self:
		HistoriaDupla.iniciar_fase(fase_historia)


func _unhandled_input(event: InputEvent) -> void:
	if _pause_menu == null or _pause_menu.visible:
		return
	if event.is_action_pressed("pausar_jogo") or event.is_action_pressed("ajuda_fases"):
		if event.is_action_pressed("ajuda_fases"):
			abrir_guia()
		else:
			pausar()
		get_viewport().set_input_as_handled()

func abrir_guia() -> void:
	if not get_tree().paused and not FluxoTela.em_transicao:
		pausar()
		_pause_menu._mostrar_guia()


func pausar() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	if _pause_menu.has_method("abrir"):
		_pause_menu.abrir()


func esta_pausado() -> bool:
	return _pause_menu != null and _pause_menu.visible
