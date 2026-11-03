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
	for _i in range(5):
		await physics_frame
	await process_frame


func make_receiver(channel: StringName) -> Node:
	var receiver: Node = load("res://scripts/signals/signal_receiver.gd").new()
	receiver.channel = channel
	root.add_child(receiver)
	return receiver


func run() -> void:
	AudioServer.set_bus_mute(0, true)
	await wait_frames()

	var single: Node2D = load("res://cenas/objects/interactables/switch.tscn").instantiate()
	single.single_use = true
	single.channel = &"test.switch.single"
	root.add_child(single)
	var single_receiver := make_receiver(&"test.switch.single")
	var single_events: Array = []
	single_receiver.received.connect(func(value): single_events.append(value))
	await wait_frames()

	check(single.get_state() == &"red", "single-use starts red")
	check(single.animation.animation == &"red", "single-use plays red")
	check(single.hitbox.get_collision_layer_value(PhysicsLayers.ENEMY_HURTBOX), "hitbox is on the enemy hurtbox layer")

	var probe := Area2D.new()
	probe.collision_layer = 0
	probe.collision_mask = 0
	probe.set_collision_mask_value(PhysicsLayers.ENEMY_HURTBOX, true)
	var probe_shape := CollisionShape2D.new()
	var probe_rect := RectangleShape2D.new()
	probe_rect.size = Vector2(18, 18)
	probe_shape.shape = probe_rect
	probe.add_child(probe_shape)
	root.add_child(probe)
	probe.global_position = single.global_position + Vector2(0, -8)
	await wait_frames()
	check(probe.get_overlapping_areas().has(single.hitbox), "hero melee area detects the switch")

	var query := PhysicsShapeQueryParameters2D.new()
	var query_shape := CircleShape2D.new()
	query_shape.radius = 2.0
	query.shape = query_shape
	query.collision_mask = 17
	query.collide_with_areas = true
	query.transform = Transform2D(0.0, single.global_position + Vector2(0, -8))
	var hits: Array[Dictionary] = single.get_world_2d().direct_space_state.intersect_shape(query)
	var projectile_found := false
	for hit in hits:
		if hit.collider == single.hitbox:
			projectile_found = true
	check(projectile_found, "projectile sweep mask detects the switch")

	single.receber_dano(10, Vector2.ZERO)
	await wait_frames()
	check(single.get_state() == &"gold", "single-use turns gold after the first hit")
	check(single.animation.animation == &"gold", "single-use plays gold")
	check(single_events == [&"gold"], "single-use publishes gold")
	check(single.hitbox.collision_layer == 0 and not single.hitbox.monitorable, "single-use disables its hitbox")

	single.receber_dano(10, Vector2.ZERO)
	single.receber_dano(10, Vector2.ZERO)
	await wait_frames()
	check(single.get_state() == &"gold" and single_events.size() == 1, "single-use cannot trigger again")

	var multi: Node2D = load("res://cenas/objects/interactables/switch.tscn").instantiate()
	multi.single_use = false
	multi.start_blue = false
	multi.channel = &"test.switch.multi"
	root.add_child(multi)
	var multi_receiver := make_receiver(&"test.switch.multi")
	var multi_events: Array = []
	multi_receiver.received.connect(func(value): multi_events.append(value))
	await wait_frames()

	check(multi.get_state() == &"red", "multiple-use starts red")
	multi.receber_dano(10, Vector2.ZERO)
	check(multi.get_state() == &"blue", "multiple-use toggles to blue")
	check(multi.animation.animation == &"blue", "multiple-use plays blue")
	multi.receber_dano(10, Vector2.ZERO)
	check(multi.get_state() == &"red", "multiple-use toggles back to red")
	check(multi.animation.animation == &"red", "multiple-use plays red")
	multi.receber_dano(10, Vector2.ZERO)
	check(multi_events == [&"blue", &"red", &"blue"], "multiple-use publishes every new state")
	check(multi.hitbox.get_collision_layer_value(PhysicsLayers.ENEMY_HURTBOX), "multiple-use keeps its hitbox active")

	var start_blue: Node2D = load("res://cenas/objects/interactables/switch.tscn").instantiate()
	start_blue.single_use = false
	start_blue.start_blue = true
	root.add_child(start_blue)
	await wait_frames()
	check(start_blue.get_state() == &"blue", "multiple-use can start blue")
	start_blue.receber_dano(10, Vector2.ZERO)
	check(start_blue.get_state() == &"red", "start-blue toggles to red")

	if failures.is_empty():
		print("SWITCH_OK: %d attack switch checks." % total)
		quit(0)
	else:
		print(failures)
		quit(1)
