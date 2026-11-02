extends SceneTree
var falhas: Array[String] = []
var total: int = 0


func _initialize() -> void:
	call_deferred("rodar")


func conferir(ok: bool, texto: String) -> void:
	total += 1
	if not ok:
		falhas.append(texto)
		push_error(texto)


func passos() -> void:
	await physics_frame
	await physics_frame
	await process_frame
	await process_frame


func rodar() -> void:
	var area: Node2D = load("res://cenas/areas/area_1.tscn").instantiate()
	root.add_child(area)
	current_scene = area
	await passos()
	var camera: Camera2D = area.get_node("CameraCompartilhada")
	conferir(camera != null, "area tem CameraCompartilhada")
	conferir(camera.alvos.size() == 2, "camera conhece os dois alvos da cena")
	conferir(camera.limites_mundo == Rect2(0, -32, 640, 432), "limites vem da propria cena")
	conferir(
		camera.zoom.x >= camera.zoom_minimo - 0.001 and camera.zoom.x <= camera.zoom_maximo + 0.001,
		"zoom inicial dentro do intervalo"
	)
	conferir(camera.limit_left == 0 and camera.limit_right == 640, "limites normais aplicados")
	var lucas: Node2D = area.get_node("Personagens/Guerreiro")
	var otto: Node2D = area.get_node("Personagens/Robo")
	lucas.set_physics_process(false)
	otto.set_physics_process(false)
	lucas.global_position = Vector2(240, 250)
	otto.global_position = Vector2(400, 250)
	await create_timer(0.5).timeout
	conferir(absf(camera.global_position.x - 320.0) < 80.0, "camera centraliza os dois alvos")
	var evento := InputEventKey.new()
	evento.physical_keycode = KEY_V
	evento.pressed = true
	Input.parse_input_event(evento)
	await passos()
	conferir(camera.visao_geral, "V abre a visao geral")
	conferir(camera.limit_left < 0, "visao geral ignora os limites da area")
	evento = InputEventKey.new()
	evento.physical_keycode = KEY_V
	evento.pressed = true
	Input.parse_input_event(evento)
	await passos()
	conferir(not camera.visao_geral, "V fecha a visao geral")
	conferir(camera.limit_left == 0, "limites da area voltam ao normal")
	if falhas.is_empty():
		print("CAMERA_AREA_OK: %d verificacoes da camera independente da area." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
