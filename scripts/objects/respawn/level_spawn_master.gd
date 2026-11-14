@tool
class_name LevelSpawnMaster
extends Node2D

@export var spawn_ativo: String = "":
	set(value):
		if spawn_ativo == value:
			return
		spawn_ativo = value
		if Engine.is_editor_hint():
			_atualizar_editor()


func _ready() -> void:
	if Engine.is_editor_hint():
		child_entered_tree.connect(_ao_mudar_filhos)
		child_exiting_tree.connect(_ao_mudar_filhos)
		child_order_changed.connect(_atualizar_editor)
		for filho in get_children():
			_conectar_filho_editor(filho)
		_atualizar_editor()
		return
	call_deferred("ativar_spawn_selecionado")


func _validate_property(property: Dictionary) -> void:
	if property.name != &"spawn_ativo":
		return
	var nomes := obter_nomes_spawns()
	if nomes.is_empty():
		property.hint = PROPERTY_HINT_NONE
		property.hint_string = ""
		return
	property.hint = PROPERTY_HINT_ENUM
	property.hint_string = ",".join(nomes)


func _get_configuration_warnings() -> PackedStringArray:
	var avisos := PackedStringArray()
	var nomes := obter_nomes_spawns()
	if nomes.is_empty():
		avisos.append("Adicione ao menos um LevelSpawn como filho direto.")
		return avisos
	if not spawn_ativo.is_empty() and not nomes.has(spawn_ativo):
		avisos.append("spawn_ativo nao existe entre os LevelSpawn filhos. O primeiro sera usado.")
	return avisos


func obter_spawns() -> Array[LevelSpawn]:
	var spawns: Array[LevelSpawn] = []
	for filho in get_children():
		if filho is LevelSpawn:
			spawns.append(filho)
	return spawns


func obter_nomes_spawns() -> PackedStringArray:
	var nomes := PackedStringArray()
	for spawn in obter_spawns():
		nomes.append(String(spawn.name))
	return nomes


func obter_spawn_ativo() -> LevelSpawn:
	var spawns := obter_spawns()
	if spawns.is_empty():
		return null
	if spawn_ativo.is_empty():
		return spawns[0]
	for spawn in spawns:
		if String(spawn.name) == spawn_ativo:
			return spawn
	push_warning("LevelSpawnMaster: spawn_ativo '%s' nao existe; usando '%s'." % [spawn_ativo, spawns[0].name])
	return spawns[0]


func ativar_spawn_selecionado() -> void:
	if Engine.is_editor_hint():
		return
	var spawn := obter_spawn_ativo()
	if spawn == null:
		push_warning("LevelSpawnMaster sem LevelSpawn filho; nenhum jogador foi posicionado.")
		return
	spawn.ativar()


func definir_spawn_ativo(nome: StringName) -> bool:
	var nomes := obter_nomes_spawns()
	if not nomes.has(String(nome)):
		return false
	spawn_ativo = String(nome)
	if is_inside_tree():
		ativar_spawn_selecionado()
	return true


func _ao_mudar_filhos(filho: Node) -> void:
	_conectar_filho_editor(filho)
	_atualizar_editor()


func _conectar_filho_editor(filho: Node) -> void:
	if filho is LevelSpawn and not filho.renamed.is_connected(_atualizar_editor):
		filho.renamed.connect(_atualizar_editor)


func _atualizar_editor() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	notify_property_list_changed()
	update_configuration_warnings()
