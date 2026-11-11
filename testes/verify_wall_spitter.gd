extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://cenas/personagens/player1.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://cenas/objects/hazards/wall_spitter_projectile.tscn")

var failures: Array[String] = []
var total: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, text: String) -> void:
	total += 1
	if not ok:
		failures.append(text)
		push_error(text)


func wait_frames(count: int = 4) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame


func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func make_world() -> Node2D:
	var world := Node2D.new()
	root.add_child(world)
	await wait_frames(2)
	return world


func make_player(world: Node2D, position: Vector2) -> Node2D:
	var player := PLAYER_SCENE.instantiate() as Node2D
	world.add_child(player)
	player.global_position = position
	player.set_physics_process(false)
	return player


func spawn_projectile(world: Node2D, position: Vector2, direction: Vector2, speed: float = 500.0, force: float = -1.0) -> Node2D:
	var projectile := PROJECTILE_SCENE.instantiate() as Node2D
	projectile.set("direction", direction)
	projectile.set("speed", speed)
	if force >= 0.0:
		projectile.set("knockback_force", force)
	world.add_child(projectile)
	projectile.global_position = position
	return projectile


func make_hole(world: Node2D, position: Vector2, size: Vector2) -> void:
	var hole := load("res://cenas/objects/hazards/hole.tscn").instantiate() as StaticBody2D
	var shape := RectangleShape2D.new()
	shape.size = size
	hole.get_node("CollisionShape2D").shape = shape
	world.add_child(hole)
	hole.global_position = position


func run() -> void:
	AudioServer.set_bus_mute(0, true)
	await wait_frames()

	var spitter_scene: PackedScene = load("res://cenas/objects/non-interactable/wall_spitter.tscn")
	var defaults := spitter_scene.instantiate()
	var projectile_defaults := PROJECTILE_SCENE.instantiate()
	var default_force: float = projectile_defaults.knockback_force
	projectile_defaults.free()
	check(is_equal_approx(defaults.shoot_interval, 1.0), "spitter defaults to a one-second interval")
	check(defaults.shoot_direction == Vector2.DOWN, "spitter defaults to firing downwards")
	check(is_equal_approx(defaults.projectile_knockback, -1.0), "spitter defers knockback to the projectile by default")
	defaults.free()

	var wall_world := await make_world()
	var wall := StaticBody2D.new()
	wall.collision_layer = 1 << (PhysicsLayers.ENVIRONMENT - 1)
	wall.collision_mask = 0
	var wall_shape := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = Vector2(160, 8)
	wall_shape.shape = wall_rect
	wall.add_child(wall_shape)
	wall_world.add_child(wall)
	wall.global_position = Vector2(300, 180)
	await wait_frames(2)
	var wall_projectile := spawn_projectile(wall_world, Vector2(300, 120), Vector2.DOWN)
	await wait_seconds(0.3)
	check(not is_instance_valid(wall_projectile), "projectile dissipates when it hits a wall")
	wall_world.queue_free()
	await wait_frames(2)

	var hit_world := await make_world()
	var hit_player := make_player(hit_world, Vector2(400, 320))
	await wait_frames(3)
	var hurt_projectile := spawn_projectile(hit_world, Vector2(400, 260), Vector2.DOWN)
	await wait_seconds(0.35)
	check(hit_player.vida_atual == 118, "unshielded projectile deals light damage")
	check(hit_player.impulso.y > 0.0, "unshielded projectile pushes in the hit direction")
	check(hit_player.impulso.length() >= default_force, "projectile applies its configured knockback force")
	check(hit_player.tempo_empurrao > 0.0, "projectile stuns the player for the knockback duration")
	hit_player.mover(Vector2.LEFT, 1.0 / 60.0)
	check(hit_player.velocidade_controle.is_zero_approx(), "stunned players cannot cancel knockback by walking")
	check(not hit_player.iniciar_ataque(), "stunned players cannot attack")
	hit_player.definir_defesa(true)
	check(not hit_player.defendendo, "stunned players cannot raise the shield")
	check(not is_instance_valid(hurt_projectile), "projectile dissipates after hitting a player")
	hit_world.queue_free()
	await wait_frames(2)

	var weak_world := await make_world()
	var weak_player := make_player(weak_world, Vector2(400, 320))
	await wait_frames(3)
	var weak_projectile := spawn_projectile(weak_world, Vector2(400, 260), Vector2.DOWN, 500.0, 50.0)
	await wait_seconds(0.35)
	check(weak_player.impulso.length() < default_force, "lower knockback force produces a smaller push")
	check(not is_instance_valid(weak_projectile), "weak projectile still dissipates on hit")
	weak_world.queue_free()
	await wait_frames(2)

	var hole_world := await make_world()
	make_hole(hole_world, Vector2(800, 620), Vector2(200, 160))
	var hole_player := make_player(hole_world, Vector2(800, 500))
	hole_player.definir_ultima_posicao_segura(Vector2(800, 500))
	hole_player.set_physics_process(true)
	await wait_frames(3)
	var fall_started := Time.get_ticks_msec()
	spawn_projectile(hole_world, Vector2(800, 440), Vector2.DOWN)
	var fell := false
	for _frame in range(120):
		await physics_frame
		if hole_player.caindo:
			fell = true
			break
	check(fell, "knockback into a hole makes the player fall")
	check(Time.get_ticks_msec() - fall_started < 600, "hole fall interrupts the knockback before the stun ends")
	await wait_seconds(hole_player.duracao_queda + 0.2)
	check(not hole_player.caindo and not hole_player.esta_morto, "player respawns after the knockback fall")
	check(hole_player.global_position.distance_to(Vector2(800, 500)) < 0.1, "hole fall respawns at the last safe ground")
	check(hole_player.vida_atual == 98, "hole fall damage is applied after the projectile damage")
	hole_world.queue_free()
	await wait_frames(2)

	var front_world := await make_world()
	var front_player := make_player(front_world, Vector2(400, 320))
	front_player.frente = Vector2.UP
	front_player.definir_defesa(true)
	var blocked_events: Array = []
	front_player.bloqueou.connect(func(): blocked_events.append(true))
	await wait_frames(3)
	var front_projectile := spawn_projectile(front_world, Vector2(400, 260), Vector2.DOWN)
	await wait_seconds(0.35)
	check(front_player.defendendo, "front-facing shield stays active")
	check(front_player.vida_atual == 120, "front-facing shield blocks projectile damage")
	check(front_player.impulso.length() < 0.01, "front-facing shield blocks projectile knockback")
	check(front_player.tempo_empurrao < 0.001, "front-facing shield blocks projectile stun")
	check(blocked_events.size() == 1, "front-facing shield emits its block signal")
	check(not is_instance_valid(front_projectile), "blocked projectile still dissipates")
	front_world.queue_free()
	await wait_frames(2)

	var back_world := await make_world()
	var back_player := make_player(back_world, Vector2(400, 320))
	back_player.frente = Vector2.DOWN
	back_player.definir_defesa(true)
	await wait_frames(3)
	var back_projectile := spawn_projectile(back_world, Vector2(400, 260), Vector2.DOWN)
	await wait_seconds(0.35)
	check(back_player.vida_atual == 118, "shield does not block a hit from behind")
	check(back_player.impulso.y > 0.0, "hit from behind still applies directional knockback")
	check(back_player.tempo_empurrao > 0.0, "hit from behind still applies stun")
	check(not is_instance_valid(back_projectile), "rear projectile dissipates after hitting a player")
	back_world.queue_free()
	await wait_frames(2)

	var spitter_world := await make_world()
	var spitter := spitter_scene.instantiate() as Node2D
	spitter.channel = &"test.wall_spitter"
	spitter.initial_delay = 0.05
	spitter.shoot_interval = 0.2
	spitter.projectile_speed = 40.0
	spitter_world.add_child(spitter)
	spitter.global_position = Vector2(600, 120)
	await wait_seconds(0.3)
	check(spitter_world.get_child_count() == 1, "spitter stays inactive until its channel turns it on")
	var bus := root.get_node("SignalBus")
	bus.publish(&"test.wall_spitter", true)
	await wait_seconds(0.56)
	check(spitter_world.get_child_count() >= 4, "spitter fires repeatedly after channel activation")
	var first_shot: Node = spitter_world.get_child(1)
	check(first_shot != null and is_equal_approx(float(first_shot.knockback_force), default_force), "spitter keeps the projectile knockback setting")
	bus.publish(&"test.wall_spitter", false)
	var count_when_off: int = spitter_world.get_child_count()
	await wait_seconds(0.4)
	check(spitter_world.get_child_count() == count_when_off, "spitter stops firing after channel deactivation")
	spitter_world.queue_free()
	await wait_frames(2)

	if failures.is_empty():
		print("WALL_SPITTER_OK: %d" % total)
		quit(0)
	else:
		print("WALL_SPITTER_FAIL: %d/%d" % [failures.size(), total])
		for failure in failures:
			print("  - " + failure)
		quit(1)
