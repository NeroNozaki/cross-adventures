extends Camera2D

@export var player1: Node2D
@export var player2: Node2D

@export var view_height: float = 575.0
@export var margin: float = 50.0
@export var smooth_speed: float = 6.0

enum State { LOCKED, FLOATING }
var state: State = State.LOCKED

var current_anchor: float = 0.0
var target_y: float = 0.0


func _ready() -> void:
	set_process(false)
	_initialize_after_spawn.call_deferred()


func _initialize_after_spawn() -> void:
	await get_tree().physics_frame
	_snap_to_players()
	set_process(true)


func _snap_to_players() -> void:
	if not player1 or not player2:
		return
	var p1_y = player1.global_position.y
	var p2_y = player2.global_position.y
	var min_y = min(p1_y, p2_y)
	var max_y = max(p1_y, p2_y)
	var avg_y = (p1_y + p2_y) * 0.5
	current_anchor = floor(avg_y / view_height) * view_height
	target_y = current_anchor
	state = State.LOCKED
	if min_y < current_anchor or max_y > current_anchor + view_height:
		state = State.FLOATING
		_update_floating_target(min_y, max_y)
	global_position.y = target_y


func _process(delta: float) -> void:
	if not player1 or not player2:
		return

	var p1_y = player1.global_position.y
	var p2_y = player2.global_position.y
	var min_y = min(p1_y, p2_y)
	var max_y = max(p1_y, p2_y)

	match state:
		State.LOCKED:
			var zone_top = current_anchor
			var zone_bottom = current_anchor + view_height

			# Unlock as soon as any player leaves the current 600px screen
			if min_y < zone_top or max_y > zone_bottom:
				state = State.FLOATING

		State.FLOATING:
			# Check if both players are now on the same 600px screen
			var screen_p1 = floor(p1_y / view_height)
			var screen_p2 = floor(p2_y / view_height)

			if screen_p1 == screen_p2:
				# Both on the same screen → lock to that screen
				current_anchor = screen_p1 * view_height
				target_y = current_anchor
				state = State.LOCKED
			else:
				# Still split → keep both players visible with margin
				_update_floating_target(min_y, max_y)

	# Smooth movement
	global_position.y = lerp(global_position.y, target_y, 1.0 - exp(-smooth_speed * delta))

	# Hard snap when very close while locked
	if state == State.LOCKED and abs(global_position.y - target_y) < 0.5:
		global_position.y = target_y


func _update_floating_target(min_y: float, max_y: float) -> void:
	# Ideal top of the camera so both players stay inside with the margin
	var desired_top = min_y - margin
	var desired_bottom = max_y + margin

	var needed_height = desired_bottom - desired_top

	if needed_height <= view_height:
		# Both fit → place the camera so players are centered between the margins
		target_y = desired_top - (view_height - needed_height) * 0.5
	else:
		# Players are farther apart than the view allows.
		# Center on the midpoint (you can change priority later if needed)
		target_y = (min_y + max_y) * 0.5 - view_height * 0.5
