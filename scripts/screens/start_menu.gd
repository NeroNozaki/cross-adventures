extends Control

@export_file("*.tscn") var proxima_cena: String = "res://cenas/areas/area_3.tscn"

func _ready():
	pass
	
func _on_play_pressed() -> void:
	_iniciar_transicao()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _iniciar_transicao() -> void:
	if proxima_cena.is_empty():
		return
	var fluxo: Node = get_node_or_null("/root/FluxoTela")
	if fluxo and fluxo.has_method("trocar"):
		fluxo.trocar(proxima_cena)
	else:
		push_error("FluxoTela nao encontrado para trocar a cena.")
	
	
