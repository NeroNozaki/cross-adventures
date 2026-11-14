class_name LevelSpawn
extends Node2D

signal team_spawned

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
	return pai != null and pai.has_method(&"ativar_spawn_selecionado")

func _assign_team() -> void:
	var heroes: Array[Node] = get_tree().get_nodes_in_group("herois")
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
