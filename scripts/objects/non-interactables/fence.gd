extends NonInteractable
class_name Fence
## Fence: on = lowered/open. Use invert_receive to swap. Use start_activated to start lowered.

@onready var static_body: StaticBody2D = $static_body
@onready var collision: CollisionShape2D = $static_body/shape
@onready var animation: AnimatedSprite2D = $animation

var _lowered := false
var _target_lowered := false
var _animating := false


func _ready() -> void:
	super._ready()
	static_body.collision_layer = 0
	static_body.collision_mask = 0
	static_body.set_collision_layer_value(PhysicsLayers.ENVIRONMENT, true)
	static_body.set_collision_mask_value(PhysicsLayers.HERO, true)
	static_body.set_collision_mask_value(PhysicsLayers.ENEMY, true)
	_lowered = _is_activated
	if _is_activated:
		animation.play("lowered")
		collision.disabled = true
	else:
		animation.play("raised")
		collision.disabled = false


func _on_activated(activated: bool) -> void:
	var target_lowered := activated
	_target_lowered = target_lowered
	if not _animating:
		_animate_to_target()


func _animate_to_target() -> void:
	_animating = true
	while _lowered != _target_lowered:
		var target := _target_lowered
		animation.play("lowering" if target else "rising")
		await animation.animation_finished
		if target != _target_lowered:
			continue
		_lowered = target
		collision.set_deferred("disabled", _lowered)
		animation.play("lowered" if _lowered else "raised")
	_animating = false
