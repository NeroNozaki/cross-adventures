extends NonInteractable
class_name Fence
## Fence: on = lowered/open. Use invert_receive to swap. Use start_activated to start lowered.

enum STATE {CLOSED, CLOSING, OPEN, OPENING}

@onready var static_body: StaticBody2D = $static_body
@onready var collision: CollisionShape2D = $static_body/shape
@onready var animation: AnimatedSprite2D = $animation

var _state: STATE = STATE.CLOSED
var _animation_token: int = 0

func _ready() -> void:
	super._ready()
	static_body.collision_layer = 0
	static_body.collision_mask = 0
	static_body.set_collision_layer_value(PhysicsLayers.ENVIRONMENT, true)
	static_body.set_collision_mask_value(PhysicsLayers.HERO, true)
	static_body.set_collision_mask_value(PhysicsLayers.ENEMY, true)
	_state = STATE.OPEN if _is_activated else STATE.CLOSED
	_sync_terminal_state()

func _on_activated(activated: bool) -> void:
	if not is_node_ready():
		return
	var target := STATE.OPEN if activated else STATE.CLOSED
	if _state == target:
		_sync_terminal_state()
		return
	if (target == STATE.OPEN and _state == STATE.OPENING) or (target == STATE.CLOSED and _state == STATE.CLOSING):
		return
	_start_transition(target)

func esta_aberta() -> bool:
	return _state == STATE.OPEN

func esta_fechada() -> bool:
	return _state == STATE.CLOSED

func esta_transicionando() -> bool:
	return _state == STATE.OPENING or _state == STATE.CLOSING

func obter_estado() -> STATE:
	return _state

func _start_transition(target: STATE) -> void:
	_animation_token += 1
	var token := _animation_token
	_state = STATE.OPENING if target == STATE.OPEN else STATE.CLOSING
	animation.play("lowering" if _state == STATE.OPENING else "rising")
	await animation.animation_finished
	if token != _animation_token:
		return
	_state = target
	_sync_terminal_state()

func _sync_terminal_state() -> void:
	var opened := _state == STATE.OPEN
	var target_animation := &"lowered" if opened else &"raised"
	if animation.animation != target_animation:
		animation.play(target_animation)
	if collision.disabled != opened:
		collision.set_deferred("disabled", opened)
