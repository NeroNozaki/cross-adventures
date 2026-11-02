extends Node2D

@onready var animation: AnimatedSprite2D = $animation
@onready var hitbox: Area2D = $hitbox
var bodies_on_button: int = 0
var pressed: bool = false

signal state_changed(pressed: bool);

func _ready() -> void:
	hitbox.collision_layer = 0
	hitbox.collision_mask = 0
	hitbox.set_collision_layer_value(PhysicsLayers.BUTTON, true)
	hitbox.set_collision_mask_value(PhysicsLayers.HERO, true)
	hitbox.body_entered.connect(_on_body_entered)
	hitbox.body_exited.connect(_on_body_exited)
	animation.play("1-not_pressed")

func _on_body_entered(_body: Node2D) -> void:
	bodies_on_button += 1
	if bodies_on_button >= 1 and not pressed:
		_press()

func _on_body_exited(_body: Node2D) -> void:
	bodies_on_button -= 1
	if bodies_on_button == 0 and pressed:
		_release()

func _press() -> void:
	if bodies_on_button >= 1:  # still on button
		animation.play("3-pressed")
		pressed = true
		state_changed.emit(pressed)
	else:  # left during transition
		_release()

func _release() -> void:
	if bodies_on_button == 0:
		animation.play("1-not_pressed")
		pressed = false
		state_changed.emit(pressed)
	else:
		_press()
