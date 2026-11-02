extends SceneTree
var failures: Array[String] = []
var total: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, text: String) -> void:
	total += 1
	if not ok:
		failures.append(text)
		push_error(text)


func wait_frames() -> void:
	await physics_frame
	await physics_frame
	await process_frame
	await process_frame


func run() -> void:
	AudioServer.set_bus_mute(0, true)
	await wait_frames()
	check(root.has_node("SignalBus"), "SignalBus autoload exists")

	var free_receiver: Node = load("res://scripts/signals/signal_receiver.gd").new()
	free_receiver.channel = &"test.bus"
	root.add_child(free_receiver)
	var received_values: Array = []
	free_receiver.received.connect(func(value): received_values.append(value))
	var free_emitter: Node = load("res://scripts/signals/signal_emitter.gd").new()
	free_emitter.channel = &"test.bus"
	root.add_child(free_emitter)
	await wait_frames()
	free_emitter.send(42)
	check(received_values == [42], "generic emitter and receiver exchange a value by channel")

	var fence: Node2D = load("res://cenas/objects/non-interactable/fence.tscn").instantiate()
	fence.channel = &"test.gate"
	root.add_child(fence)
	var button: Node2D = load("res://cenas/objects/interactables/button.tscn").instantiate()
	button.channel = &"test.gate"
	root.add_child(button)
	await wait_frames()

	button._on_body_entered(null)
	await create_timer(2.0).timeout
	check(fence._lowered, "pressed button lowers the fence")
	check(fence.collision.disabled, "lowered fence opens the passage")
	check(fence.animation.animation == &"lowered", "animation ends in lowered")

	button._on_body_exited(null)
	await create_timer(2.0).timeout
	check(not fence._lowered, "released button raises the fence")
	check(not fence.collision.disabled, "raised fence blocks the passage again")
	check(fence.animation.animation == &"raised", "animation ends in raised")

	if failures.is_empty():
		print("SIGNALS_OK: %d signal bus, emitter and receiver checks." % total)
		quit(0)
	else:
		print(failures)
		quit(1)
