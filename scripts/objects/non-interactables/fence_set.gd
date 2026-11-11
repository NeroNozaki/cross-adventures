extends NonInteractable
class_name FenceSet

const FENCE_SCRIPT := preload("res://scripts/objects/non-interactables/fence.gd")

@export var limpar_canais_dos_filhos: bool = true

var _partes: Array[Node2D] = []


func _ready() -> void:
	_coletar_partes()
	if channel != &"" and limpar_canais_dos_filhos:
		_limpar_canais_das_partes()
	super._ready()
	_aplicar_nas_partes(_is_activated)


func definir_canal(novo_canal: StringName) -> void:
	if novo_canal != &"" and limpar_canais_dos_filhos:
		_limpar_canais_das_partes()
	super.definir_canal(novo_canal)


func _on_activated(activated: bool) -> void:
	_aplicar_nas_partes(activated)


func _coletar_partes() -> void:
	_partes.clear()
	for node in find_children("*", "", true, false):
		if node.get_script() == FENCE_SCRIPT:
			_partes.append(node as Node2D)


func _limpar_canais_das_partes() -> void:
	for parte in _partes:
		if is_instance_valid(parte):
			parte.definir_canal(&"")


func _aplicar_nas_partes(activated: bool) -> void:
	for parte in _partes:
		if is_instance_valid(parte):
			parte.definir_ativado(activated)
