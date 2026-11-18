extends Interactable
## Button sends on/off. Toggle invert_send to swap behavior.

@onready var animation: AnimatedSprite2D = $animation
@onready var hitbox: Area2D = $hitbox
@export var single_use := false

var bodies_on_button: int = 0
var pressed: bool = false
var _encaixe: Tween

signal state_changed(pressed: bool)


func _ready() -> void:
	super._ready()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 0
	hitbox.set_collision_layer_value(PhysicsLayers.BUTTON, true)
	hitbox.set_collision_mask_value(PhysicsLayers.HERO, true)
	hitbox.body_entered.connect(_on_body_entered)
	hitbox.body_exited.connect(_on_body_exited)
	animation.play("1-not_pressed")


func _on_body_entered(_body: Node2D) -> void:
	if travado:
		return
	bodies_on_button += 1
	if bodies_on_button >= 1 and not pressed:
		_press()


func _on_body_exited(_body: Node2D) -> void:
	if travado:
		return
	bodies_on_button = maxi(0, bodies_on_button - 1)
	if bodies_on_button == 0 and pressed:
		_release()


func _press() -> void:
	if travado:
		return
	if bodies_on_button >= 1 and not pressed:
		pressed = true
		_animar_placa(&"3-pressed")
		if has_signal("state_changed"):
			state_changed.emit(pressed)
		send_on_off(pressed)


func _release() -> void:
	if travado or single_use or not pressed:
		return
	if bodies_on_button == 0:
		pressed = false
		_animar_placa(&"1-not_pressed")
		if has_signal("state_changed"):
			state_changed.emit(pressed)
		send_on_off(pressed)


func travar_estado_atual() -> void:
	if travado:
		return
	travado = true
	single_use = true
	bodies_on_button = 999 if pressed else 0
	if _encaixe and _encaixe.is_valid():
		_encaixe.kill()
	animation.play("3-pressed" if pressed else "1-not_pressed")

func _animar_placa(destino: StringName) -> void:
	if _encaixe and _encaixe.is_valid():
		_encaixe.kill()
	animation.play(&"2-transition")
	_encaixe = create_tween()
	_encaixe.tween_interval(0.065)
	_encaixe.tween_callback(animation.play.bind(destino))
