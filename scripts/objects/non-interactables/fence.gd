extends Node2D
## Fence listens to a signal channel and raises/lowers based on the received value.
## It does not know the button or any emitter.

@onready var static_body: StaticBody2D = $static_body
@onready var collision: CollisionShape2D = $static_body/shape
@onready var animation: AnimatedSprite2D = $animation
@onready var receiver: Node = $SignalReceiver
@export var channel: StringName = &"mechanism.button"

var _lowered := false
var _target_lowered := false
var _animating := false


func _ready() -> void:
	static_body.collision_layer = 0
	static_body.collision_mask = 0
	static_body.set_collision_layer_value(PhysicsLayers.ENVIRONMENT, true)
	static_body.set_collision_mask_value(PhysicsLayers.HERO, true)
	static_body.set_collision_mask_value(PhysicsLayers.ENEMY, true)
	animation.play("raised")
	if channel != &"":
		receiver.configure(channel)
	receiver.received.connect(_on_received)


func _on_received(value: Variant) -> void:
	_target_lowered = bool(value)
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
