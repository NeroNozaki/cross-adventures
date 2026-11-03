extends Node2D
## Attack-activated switch.
## Single use: starts red, turns gold on the first hit, then ignores damage forever.
## Multiple use: starts red or blue and toggles between them on every hit.
## Published value is the new state: &"red", &"blue" or &"gold".

signal state_changed(state: StringName)
signal turned_red
signal turned_blue
signal turned_gold

const RED := &"red"
const BLUE := &"blue"
const GOLD := &"gold"

@export var single_use: bool = true
@export var start_blue: bool = false
@export var channel: StringName = &"switch"
@export var altura_nivel: int = 0

var equipe: int = 1
var esta_morto: bool = false
var pulando: bool = false
var vida_atual: int = 1
var state: StringName = RED

var _spent: bool = false

@onready var animation: AnimatedSprite2D = $animation
@onready var hitbox: Area2D = $hitbox


func _ready() -> void:
	hitbox.collision_layer = 0
	hitbox.collision_mask = 0
	hitbox.set_collision_layer_value(PhysicsLayers.ENEMY_HURTBOX, true)
	hitbox.monitoring = true
	hitbox.monitorable = true
	state = RED if single_use or not start_blue else BLUE
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
		_set_state(GOLD)
		hitbox.set_deferred("monitorable", false)
		hitbox.set_deferred("collision_layer", 0)
		return
	_set_state(BLUE if state == RED else RED)


func _set_state(new_state: StringName) -> void:
	state = new_state
	animation.play(state)
	state_changed.emit(state)
	match state:
		RED:
			turned_red.emit()
		BLUE:
			turned_blue.emit()
		GOLD:
			turned_gold.emit()
	SignalBus.publish(channel, state)


func _restore_hit_marker() -> void:
	vida_atual = 1
