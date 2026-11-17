class_name LevelSpawn
extends Node2D

signal team_spawned

enum Alvo {
	TODOS,
	PLAYER1,
	PLAYER2,
}

@export var alvo: Alvo = Alvo.TODOS
@export var team_spacing: float = 64.0
@export var move_team_on_ready: bool = true

@onready var respawn_point: Marker2D = $RespawnPoint

func _ready() -> void:
	if _gerenciado_pelo_master():
		return
	call_deferred("ativar")

func ativar() -> void:
	_assign_team()

func _gerenciado_pelo_master() -> bool:
	var pai := get_parent()
	return pai != null and pai.has_method(&"ativar_spawns_selecionados")

func _assign_team() -> void:
	var heroes: Array[Node] = []
	for hero in get_tree().get_nodes_in_group("herois"):
		if _hero_corresponde_ao_alvo(hero):
			heroes.append(hero)
	heroes.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
	var count: int = heroes.size()
	for index in range(count):
		var hero: Node = heroes[index]
		if not hero.has_method("definir_ponto_renascimento"):
			continue
		var offset: Vector2 = Vector2((float(index) - float(count - 1) * 0.5) * team_spacing, 0.0)
		var point: Vector2 = respawn_point.global_position + offset
		hero.call(&"definir_ponto_renascimento", point)
		hero.call(&"definir_ultima_posicao_segura", point)
		hero.call(&"definir_ponto_seguro_inicial", point)
		if move_team_on_ready and hero is Node2D and not hero.get("esta_morto"):
			(hero as Node2D).global_position = point
	team_spawned.emit()

func _hero_corresponde_ao_alvo(hero: Node) -> bool:
	match alvo:
		Alvo.PLAYER1:
			return _hero_eh_player(hero, "player1")
		Alvo.PLAYER2:
			return _hero_eh_player(hero, "player2")
		_:
			return true

func _hero_eh_player(hero: Node, nome_player: String) -> bool:
	var cena := String(hero.scene_file_path).get_file().get_basename()
	if cena == nome_player:
		return true
	var script_hero: Script = hero.get_script() as Script
	if script_hero != null:
		var caminho_script := String(script_hero.resource_path).get_file().get_basename()
		if caminho_script == nome_player:
			return true
	return String(hero.name).to_lower() == nome_player
