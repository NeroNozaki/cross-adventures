extends Interactable
## Attack-activated switch. Sends true/false on/off via channel.
## single_use: default sends true on hit (use invert_send to send false).
## multi-use: toggles true/false each hit; use invert_send to swap mapping.

const RED := &"red"
const BLUE := &"blue"
const GOLD := &"gold"

@export var single_use: bool = true
@export var start_blue: bool = false
@export var altura_nivel: int = 0

var equipe: int = 1
var esta_morto: bool = false
var pulando: bool = false
var vida_atual: int = 1
var state: StringName = RED

var _spent: bool = false
var _is_on: bool = true

@onready var animation: AnimatedSprite2D = $animation
@onready var hitbox: Area2D = $hitbox


func _ready() -> void:
	super._ready()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 0
	hitbox.set_collision_layer_value(PhysicsLayers.ENEMY_HURTBOX, true)
	hitbox.monitoring = true
	hitbox.monitorable = true
	if single_use:
		_is_on = not invert_send  # default true unless inverted
		state = RED
	else:
		_is_on = start_blue
		state = BLUE if start_blue else RED
	animation.play(state)


func receber_dano(_valor: int, _origem: Vector2) -> void:
	if _spent:
		return
	_trigger()
	# Attack code confirms a hit when this value drops; it is restored next frame.
	vida_atual = 0
	call_deferred("_restore_hit_marker")


func get_state() -> StringName:
	return state


func is_spent() -> bool:
	return _spent


func _trigger() -> void:
	if single_use:
		_spent = true
		_is_on = !invert_send
		_set_state(GOLD)
		hitbox.set_deferred("monitorable", false)
		hitbox.set_deferred("collision_layer", 0)
		send_on_off(_is_on)
		return
	_is_on = !_is_on
	_set_state(BLUE if _is_on else RED)
	send_on_off(_is_on)


func _set_state(new_state: StringName) -> void:
	state = new_state
	animation.play(state)
	# maintain backward compat if anything listens
	if has_signal("state_changed"):
		pass
	match state:
		RED:
			if has_signal("turned_red"):
				pass
		BLUE:
			if has_signal("turned_blue"):
				pass
		GOLD:
			if has_signal("turned_gold"):
				pass
	# publish visual state too if someone expects old values? but we want bool - keep minimal compat
	SignalBus.publish(channel, state) if channel != &"" else null


func _restore_hit_marker() -> void:
	vida_atual = 1
