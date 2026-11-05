extends SceneTree

var falhas: Array[String] = []
var total: int = 0


func _initialize() -> void:
	create_timer(15.0).timeout.connect(func():
		push_error("Timeout do teste da camera")
		quit(2)
	)
	call_deferred("rodar")


func conferir(ok: bool, texto: String) -> void:
	total += 1
	if not ok:
		falhas.append(texto)
		push_error(texto)


func passos(count: int = 3) -> void:
	for _i in range(count):
		await physics_frame
	await process_frame


func rodar() -> void:
	var mundo := Node2D.new()
	root.add_child(mundo)
	current_scene = mundo

	var player1: Node2D = load("res://cenas/personagens/player1.tscn").instantiate()
	player1.set_physics_process(false)
	mundo.add_child(player1)
	player1.global_position = Vector2.ZERO
	var player2: Node2D = load("res://cenas/personagens/player2.tscn").instantiate()
	player2.set_physics_process(false)
	mundo.add_child(player2)
	player2.global_position = Vector2.ZERO

	var camera: Camera2D = load("res://scripts/objects/camera/camera2D.gd").new()
	camera.player1 = player1
	camera.player2 = player2
	mundo.add_child(camera)
	camera.global_position = Vector2.ZERO

	var spawn: Node2D = load("res://cenas/objects/respawn/level_spawn.tscn").instantiate()
	spawn.set("team_spacing", 64.0)
	mundo.add_child(spawn)
	spawn.global_position = Vector2(1000, 720)
	await passos(5)

	conferir(player1.global_position.y == 720.0, "level spawn move Player1 antes da camera")
	conferir(player2.global_position.y == 720.0, "level spawn move Player2 antes da camera")
	conferir(is_equal_approx(camera.current_anchor, 575.0), "camera usa a ancora do spawn, nao a posicao inicial")
	conferir(is_equal_approx(camera.global_position.y, 575.0), "camera nasce enquadrada nos personagens")
	conferir(camera.state == camera.State.LOCKED, "camera trava no quadro do spawn")

	player1.global_position = Vector2(0, 600)
	player2.global_position = Vector2(0, 700)
	await passos()
	conferir(camera.state == camera.State.LOCKED, "camera permanece travada com os dois no mesmo quadro")
	conferir(is_equal_approx(camera.global_position.y, 575.0), "camera nao pula ao andar dentro do quadro")

	player1.global_position = Vector2(0, 100)
	player2.global_position = Vector2(0, 1000)
	await passos()
	conferir(camera.state == camera.State.FLOATING, "camera flutua quando os herois se separam")
	conferir(is_equal_approx(camera.target_y, 262.5), "camera calcula o centro entre os herois")

	if falhas.is_empty():
		print("CAMERA_AREA_OK: %d verificacoes da camera no spawn." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
