extends Node2D
## Button presses when heroes stand on it and publishes state to the signal bus.
## It does not know fences, doors, or any receiver.

@onready var animation: AnimatedSprite2D = $animation
@onready var hitbox: Area2D = $hitbox
@onready var emitter: Node = $SignalEmitter
@export var single_use := false
@export var channel: StringName = &"mechanism.button"

var bodies_on_button: int = 0
var pressed: bool = false

signal state_changed(pressed: bool)


func _ready() -> void:
	if channel != &"":
		emitter.channel = channel
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
	bodies_on_button = maxi(0, bodies_on_button - 1)
	if bodies_on_button == 0 and pressed:
		_release()


func _press() -> void:
	if bodies_on_button >= 1 and not pressed:
		pressed = true
		animation.play("3-pressed")
		state_changed.emit(pressed)
		emitter.send(pressed)


func _release() -> void:
	if single_use or not pressed:
		return
	if bodies_on_button == 0:
		pressed = false
		animation.play("1-not_pressed")
		state_changed.emit(pressed)
		emitter.send(pressed)
