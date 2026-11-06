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
	var bus: Node = root.get_node("SignalBus")

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
	await wait_frames()
	check(fence.obter_estado() == Fence.STATE.OPENING, "pressed button starts opening state")
	check(not fence.collision.disabled, "opening fence still blocks the passage")
	await create_timer(2.0).timeout
	check(fence.esta_aberta(), "pressed button opens the fence")
	check(fence.obter_estado() == Fence.STATE.OPEN, "opening animation ends in OPEN")
	check(fence.collision.disabled, "lowered fence opens the passage")
	check(fence.animation.animation == &"lowered", "animation ends in lowered")

	var open_frame: int = fence.animation.frame
	fence.definir_ativado(true)
	await wait_frames()
	check(fence.esta_aberta(), "repeated activation keeps the fence OPEN")
	check(fence.animation.animation == &"lowered" and fence.animation.frame == open_frame, "repeated activation does not replay the opening animation")
	check(fence.collision.disabled, "repeated activation keeps the passage open")

	button._on_body_exited(null)
	await wait_frames()
	check(fence.obter_estado() == Fence.STATE.CLOSING, "released button starts closing state")
	check(fence.collision.disabled, "closing fence keeps the passage open until it is raised")
	await create_timer(2.0).timeout
	check(fence.esta_fechada(), "released button closes the fence")
	check(fence.animation.animation == &"raised", "animation ends in raised")
	check(not fence.collision.disabled, "raised fence blocks the passage again")

	var start_open: Node2D = load("res://cenas/objects/non-interactable/fence.tscn").instantiate()
	start_open.start_activated = true
	root.add_child(start_open)
	await wait_frames()
	check(start_open.esta_aberta(), "start_activated begins in OPEN")
	check(start_open.animation.animation == &"lowered", "start_activated begins with lowered visual")
	check(start_open.collision.disabled, "start_activated begins with open collision")

	var reversing: Node2D = load("res://cenas/objects/non-interactable/fence.tscn").instantiate()
	root.add_child(reversing)
	await wait_frames()
	reversing.definir_ativado(true)
	await create_timer(0.15).timeout
	check(reversing.obter_estado() == Fence.STATE.OPENING, "fence reaches OPENING before reversal")
	reversing.definir_ativado(false)
	await wait_frames()
	check(reversing.obter_estado() == Fence.STATE.CLOSING, "mid-animation reversal changes to CLOSING")
	await create_timer(1.2).timeout
	check(reversing.esta_fechada(), "reversed fence settles CLOSED")
	check(not reversing.collision.disabled, "reversed fence restores collision")
	check(reversing.animation.animation == &"raised", "reversed fence settles on raised visual")

	check(not fence._interpret(null), "null signal payload is ignored")
	check(not fence._interpret(Vector2.ONE), "vector signal payload is ignored")
	check(not fence._interpret(["on"]), "array signal payload is ignored")

	var fence_set: Node2D = load("res://cenas/objects/non-interactable/fence_set.tscn").instantiate()
	fence_set.channel = &"test.set"
	root.add_child(fence_set)
	var set_button: Node2D = load("res://cenas/objects/interactables/button.tscn").instantiate()
	set_button.channel = &"test.set"
	root.add_child(set_button)
	await wait_frames()

	var set_fences: Array = fence_set.find_children("fence*", "", true, false)
	check(set_fences.size() == 3, "fence set collects its fence children")
	var children_clear := true
	for part in set_fences:
		if part.channel != &"":
			children_clear = false
	check(children_clear, "fence set clears child channels when using a parent channel")

	bus.publish(&"test.set", null)
	bus.publish(&"test.set", Vector2.ONE)
	bus.publish(&"test.set", ["on"])
	await wait_frames()
	var stayed_raised := true
	for part in set_fences:
		if part.esta_aberta():
			stayed_raised = false
	check(stayed_raised, "unsupported payloads do not activate the fence set")

	set_button._on_body_entered(null)
	await create_timer(2.0).timeout
	var all_lowered := true
	var all_open := true
	for part in set_fences:
		if not part.esta_aberta():
			all_lowered = false
		if not part.collision.disabled:
			all_open = false
	check(all_lowered, "one channel lowers every fence in the set")
	check(all_open, "one channel opens every passage in the set")

	set_button._on_body_exited(null)
	await create_timer(2.0).timeout
	var all_raised := true
	var all_closed := true
	for part in set_fences:
		if part.esta_aberta():
			all_raised = false
		if part.collision.disabled:
			all_closed = false
	check(all_raised, "releasing the channel raises every fence in the set")
	check(all_closed, "releasing the channel closes every passage in the set")

	var switch_set: Node2D = load("res://cenas/objects/non-interactable/fence_set.tscn").instantiate()
	switch_set.channel = &"test.set.switch"
	root.add_child(switch_set)
	var shared_switch: Node2D = load("res://cenas/objects/interactables/switch.tscn").instantiate()
	shared_switch.channel = &"test.set.switch"
	root.add_child(shared_switch)
	await wait_frames()

	shared_switch.receber_dano(10, Vector2.ZERO)
	await create_timer(2.0).timeout
	var switch_fences: Array = switch_set.find_children("fence*", "", true, false)
	var switch_lowered := true
	var switch_open := true
	for part in switch_fences:
		if not part.esta_aberta():
			switch_lowered = false
		if not part.collision.disabled:
			switch_open = false
	check(switch_lowered, "switch sharing a channel lowers the fence set")
	check(switch_open, "switch sharing a channel opens the passage")

	if failures.is_empty():
		print("SIGNALS_OK: %d signal bus, emitter and receiver checks." % total)
		quit(0)
	else:
		print(failures)
		quit(1)
