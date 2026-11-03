class_name Checkpoint
extends Area2D

signal reached

@export var team_wide: bool = true
@export var team_spacing: float = 48.0
@export var one_shot: bool = false

@onready var respawn_point: Marker2D = $RespawnPoint
@onready var visual: Polygon2D = $Visual
var is_active: bool = false

func _ready() -> void:
	collision_layer = 0
	set_collision_mask_value(PhysicsLayers.HERO, true)
	monitorable = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("herois") or body.get("esta_morto") == true:
		return
	if team_wide:
		_assign_team()
	else:
		body.call(&"definir_ponto_renascimento", respawn_point.global_position)
	_mark_active()

func _assign_team() -> void:
	var heroes: Array[Node] = get_tree().get_nodes_in_group("herois")
	heroes.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
	var count: int = heroes.size()
	for index in range(count):
		var hero: Node = heroes[index]
		if not hero.has_method("definir_ponto_renascimento"):
			continue
		var offset: Vector2 = Vector2((float(index) - float(count - 1) * 0.5) * team_spacing, 0.0)
		hero.call(&"definir_ponto_renascimento", respawn_point.global_position + offset)

func _mark_active() -> void:
	if is_active:
		return
	is_active = true
	visual.color = Color("8df0a1")
	if one_shot:
		set_deferred("monitoring", false)
	reached.emit()
