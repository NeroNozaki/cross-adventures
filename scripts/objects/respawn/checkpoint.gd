class_name Checkpoint
extends Node2D

signal reached

static var checkpoint_ativo: Checkpoint

@export var team_spacing: float = 48.0
@export var one_shot: bool = false

@onready var trigger: Area2D = $Trigger
@onready var respawn_point: Marker2D = $RespawnPoint
@onready var visual: Polygon2D = _obter_visual()
var is_active: bool = false


func _obter_visual() -> Polygon2D:
	var marcador: Node = get_node_or_null("RespawnPoint/Visual")
	if marcador == null:
		marcador = get_node_or_null("Trigger/Visual")
	return marcador as Polygon2D


func _ready() -> void:
	trigger.collision_layer = 0
	trigger.set_collision_mask_value(PhysicsLayers.HERO, true)
	trigger.monitorable = false
	trigger.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("herois") or body.get("esta_morto") == true:
		return
	if is_instance_valid(checkpoint_ativo) and checkpoint_ativo != self:
		checkpoint_ativo.definir_ativo(false)
	checkpoint_ativo = self
	if not body.call(&"esta_sobre_terreno_instavel"):
		body.call(&"definir_ultima_posicao_segura", body.global_position)
	_assign_team()
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


func definir_ativo(ativo: bool) -> void:
	is_active = ativo
	if is_instance_valid(visual):
		visual.color = Color("8df0a1") if ativo else Color(0.96, 0.78, 0.32, 1.0)


func _mark_active() -> void:
	if is_active:
		return
	definir_ativo(true)
	if one_shot:
		trigger.set_deferred("monitoring", false)
	reached.emit()
