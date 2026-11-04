extends Node2D

@export var speed: float = 220.0
@export var damage: int = 6
@export var knockback_force: float = 300.0
@export var max_lifetime: float = 6.0
var direction: Vector2 = Vector2.DOWN

var _finished: bool = false
var _life_left: float = 0.0

@onready var sweep: ShapeCast2D = $sweep
@onready var animation: AnimatedSprite2D = $animation


func _ready() -> void:
	top_level = true
	_life_left = maxf(max_lifetime, 0.1)
	if direction.length_squared() < 0.001:
		direction = Vector2.DOWN
	direction = direction.normalized()
	rotation = direction.angle()
	sweep.collision_mask = 0
	sweep.set_collision_mask_value(PhysicsLayers.ENVIRONMENT, true)
	sweep.set_collision_mask_value(PhysicsLayers.HERO_HURTBOX, true)
	sweep.collide_with_areas = true
	sweep.collide_with_bodies = true
	animation.play(&"default")


func _physics_process(delta: float) -> void:
	if _finished:
		return
	_life_left -= delta
	if _life_left <= 0.0:
		_finish()
		return
	var step: float = maxf(speed, 0.0) * delta
	if step <= 0.0:
		return
	_sweep_move(step)


func _sweep_move(remaining: float) -> void:
	if remaining <= 0.001:
		return
	sweep.target_position = direction * remaining
	sweep.force_shapecast_update()
	if not sweep.is_colliding():
		global_position += direction * remaining
		return
	var fraction: float = clampf(sweep.get_closest_collision_safe_fraction(), 0.0, 1.0)
	global_position += direction * remaining * fraction
	_hit(sweep.get_collider(0))
	_finish()


func _hit(collider: Object) -> void:
	if collider is Area2D:
		var area := collider as Area2D
		var target: Node = area.get_parent()
		if target != null and target.has_method("receive_projectile_hit") and int(target.get("equipe")) == 0:
			var impact_origin := global_position - direction * 4.0
			target.receive_projectile_hit(damage, impact_origin, direction, knockback_force)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	set_physics_process(false)
	queue_free()
