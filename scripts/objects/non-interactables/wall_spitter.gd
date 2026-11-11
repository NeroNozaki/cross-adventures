extends NonInteractable

@export var projectile_scene: PackedScene = preload("res://cenas/objects/hazards/wall_spitter_projectile.tscn")
@export var shoot_interval: float = 1.0
@export var initial_delay: float = 1.0
@export var shoot_direction: Vector2 = Vector2.DOWN
@export var muzzle_distance: float = 18.0
@export var projectile_speed: float = -1.0
@export var projectile_damage: int = -1
@export var projectile_knockback: float = -1.0

var _time_until_shot: float = 0.0


func _ready() -> void:
	super._ready()
	_time_until_shot = maxf(initial_delay, 0.0)
	set_physics_process(_is_activated)


func _on_activated(activated: bool) -> void:
	if activated:
		_time_until_shot = maxf(initial_delay, 0.0)
	set_physics_process(activated)


func _physics_process(delta: float) -> void:
	if not _is_activated or projectile_scene == null:
		return
	_time_until_shot -= delta
	if _time_until_shot > 0.0:
		return
	_shoot()
	_time_until_shot = maxf(shoot_interval, 0.05)


func _shoot() -> void:
	var fire_direction := _fire_direction()
	var projectile := projectile_scene.instantiate() as Node2D
	if projectile == null:
		return
	projectile.set("direction", fire_direction)
	if projectile_speed >= 0.0:
		projectile.set("speed", projectile_speed)
	if projectile_damage >= 0:
		projectile.set("damage", projectile_damage)
	if projectile_knockback >= 0.0:
		projectile.set("knockback_force", projectile_knockback)
	var host: Node = get_parent()
	if host == null:
		host = get_tree().current_scene
	if host == null:
		projectile.queue_free()
		return
	host.add_child(projectile)
	projectile.global_position = global_position + fire_direction * muzzle_distance


func _fire_direction() -> Vector2:
	var direction := global_transform.basis_xform(shoot_direction)
	if direction.length_squared() < 0.001:
		return Vector2.DOWN
	return direction.normalized()
