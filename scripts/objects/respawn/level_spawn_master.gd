@tool
class_name LevelSpawnMaster
extends Node2D

@export var spawn_ativo_player1: String = "":
	set(value):
		if spawn_ativo_player1 == value:
			return
		spawn_ativo_player1 = value
		if Engine.is_editor_hint():
			_atualizar_editor()


@export var spawn_ativo_player2: String = "":
	set(value):
		if spawn_ativo_player2 == value:
			return
		spawn_ativo_player2 = value
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
	call_deferred("ativar_spawns_selecionados")


func _validate_property(property: Dictionary) -> void:
	var nomes := PackedStringArray()
	if property.name == &"spawn_ativo_player1":
		nomes = obter_nomes_spawns_player1()
	elif property.name == &"spawn_ativo_player2":
		nomes = obter_nomes_spawns_player2()
	else:
		return
	if nomes.is_empty():
		property.hint = PROPERTY_HINT_NONE
		property.hint_string = ""
		return
	property.hint = PROPERTY_HINT_ENUM
	property.hint_string = ",".join(nomes)


func _get_configuration_warnings() -> PackedStringArray:
	var avisos := PackedStringArray()
	var todos := obter_spawns()
	if todos.is_empty():
		avisos.append("Adicione LevelSpawnPlayer1 e LevelSpawnPlayer2 como filhos diretos.")
		return avisos
	var nomes_player1 := obter_nomes_spawns_player1()
	var nomes_player2 := obter_nomes_spawns_player2()
	if nomes_player1.is_empty():
		avisos.append("Adicione ao menos um LevelSpawnPlayer1 como filho direto.")
	elif not spawn_ativo_player1.is_empty() and not nomes_player1.has(spawn_ativo_player1):
		avisos.append("spawn_ativo_player1 nao existe entre os spawns de Player1. O primeiro sera usado.")
	if nomes_player2.is_empty():
		avisos.append("Adicione ao menos um LevelSpawnPlayer2 como filho direto.")
	elif not spawn_ativo_player2.is_empty() and not nomes_player2.has(spawn_ativo_player2):
		avisos.append("spawn_ativo_player2 nao existe entre os spawns de Player2. O primeiro sera usado.")
	return avisos


func obter_spawns() -> Array[LevelSpawn]:
	var spawns: Array[LevelSpawn] = []
	for filho in get_children():
		if filho is LevelSpawn:
			spawns.append(filho)
	return spawns


func obter_spawns_player1() -> Array[LevelSpawn]:
	return _obter_spawns_por_alvo(LevelSpawn.Alvo.PLAYER1)


func obter_spawns_player2() -> Array[LevelSpawn]:
	return _obter_spawns_por_alvo(LevelSpawn.Alvo.PLAYER2)


func _obter_spawns_por_alvo(alvo: LevelSpawn.Alvo) -> Array[LevelSpawn]:
	var spawns: Array[LevelSpawn] = []
	for spawn in obter_spawns():
		if spawn.alvo == alvo:
			spawns.append(spawn)
	return spawns


func obter_nomes_spawns() -> PackedStringArray:
	var nomes := PackedStringArray()
	for spawn in obter_spawns():
		nomes.append(String(spawn.name))
	return nomes


func obter_nomes_spawns_player1() -> PackedStringArray:
	return _obter_nomes(obter_spawns_player1())


func obter_nomes_spawns_player2() -> PackedStringArray:
	return _obter_nomes(obter_spawns_player2())


func _obter_nomes(spawns: Array[LevelSpawn]) -> PackedStringArray:
	var nomes := PackedStringArray()
	for spawn in spawns:
		nomes.append(String(spawn.name))
	return nomes


func obter_spawn_ativo_player1() -> LevelSpawn:
	return _obter_spawn_ativo(spawn_ativo_player1, obter_spawns_player1(), "spawn_ativo_player1")


func obter_spawn_ativo_player2() -> LevelSpawn:
	return _obter_spawn_ativo(spawn_ativo_player2, obter_spawns_player2(), "spawn_ativo_player2")


func _obter_spawn_ativo(nome: String, spawns: Array[LevelSpawn], campo: String) -> LevelSpawn:
	if spawns.is_empty():
		return null
	if nome.is_empty():
		return spawns[0]
	for spawn in spawns:
		if String(spawn.name) == nome:
			return spawn
	push_warning("LevelSpawnMaster: %s '%s' nao existe; usando '%s'." % [campo, nome, spawns[0].name])
	return spawns[0]


func ativar_spawns_selecionados() -> void:
	if Engine.is_editor_hint():
		return
	var spawn_player1 := obter_spawn_ativo_player1()
	var spawn_player2 := obter_spawn_ativo_player2()
	if spawn_player1 == null and spawn_player2 == null:
		push_warning("LevelSpawnMaster sem LevelSpawnPlayer1/Player2 filho; nenhum jogador foi posicionado.")
		return
	if spawn_player1 == null:
		push_warning("LevelSpawnMaster sem LevelSpawnPlayer1 filho; Player1 nao foi posicionado.")
	else:
		spawn_player1.ativar()
	if spawn_player2 == null:
		push_warning("LevelSpawnMaster sem LevelSpawnPlayer2 filho; Player2 nao foi posicionado.")
	else:
		spawn_player2.ativar()


func ativar_spawn_selecionado() -> void:
	ativar_spawns_selecionados()


func definir_spawn_ativo_player1(nome: StringName) -> bool:
	var nomes := obter_nomes_spawns_player1()
	if not nomes.has(String(nome)):
		return false
	spawn_ativo_player1 = String(nome)
	if is_inside_tree():
		_ativar_spawn_player1()
	return true


func definir_spawn_ativo_player2(nome: StringName) -> bool:
	var nomes := obter_nomes_spawns_player2()
	if not nomes.has(String(nome)):
		return false
	spawn_ativo_player2 = String(nome)
	if is_inside_tree():
		_ativar_spawn_player2()
	return true


func _ativar_spawn_player1() -> void:
	if Engine.is_editor_hint() or not is_inside_tree():
		return
	var spawn := obter_spawn_ativo_player1()
	if spawn != null:
		spawn.ativar()


func _ativar_spawn_player2() -> void:
	if Engine.is_editor_hint() or not is_inside_tree():
		return
	var spawn := obter_spawn_ativo_player2()
	if spawn != null:
		spawn.ativar()


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
