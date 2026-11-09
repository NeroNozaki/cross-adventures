extends SceneTree

var falhas: Array[String] = []
var total := 0


func _initialize() -> void:
	call_deferred("rodar")


func conferir(ok: bool, texto: String) -> void:
	total += 1
	if not ok:
		falhas.append(texto)
		push_error(texto)


func quadros() -> void:
	await physics_frame
	await process_frame
	await physics_frame


func rodar() -> void:
	AudioServer.set_bus_mute(0, true)
	var area: Node2D = load("res://cenas/areas/area_3.tscn").instantiate()
	root.add_child(area)
	await quadros()

	var button2: Node2D = area.get_node("objects/button2")
	var button3: Node2D = area.get_node("objects/button3")
	var fence_set3: Node2D = area.get_node("objects/fence_set3")
	var partes: Array = fence_set3.find_children("fence*", "", true, false)
	conferir(partes.size() == 3, "fence_set3 possui tres cercas")

	var abertas := func() -> bool:
		for parte in partes:
			if not parte.esta_aberta():
				return false
		return true

	conferir(not abertas.call(), "fence_set3 comeca fechado")

	button2._on_body_entered(null)
	await quadros()
	conferir(not abertas.call(), "button2 sozinho nao abre fence_set3")
	conferir(not button2.single_use and not button3.single_use, "um botao sozinho nao trava o conjunto")

	button2._on_body_exited(null)
	await quadros()
	button3._on_body_entered(null)
	await quadros()
	conferir(not abertas.call(), "button3 sozinho nao abre fence_set3")

	button2._on_body_entered(null)
	await create_timer(1.2).timeout
	conferir(abertas.call(), "os dois botoes juntos abrem fence_set3")
	conferir(button2.single_use and button3.single_use, "os dois botoes ficam travados")
	conferir(button2.pressed and button3.pressed, "os dois botoes permanecem pressionados")

	button3._on_body_exited(null)
	button2._on_body_exited(null)
	await create_timer(1.2).timeout
	conferir(abertas.call(), "fence_set3 permanece aberto depois de soltar os botoes")

	area.free()
	await create_timer(0.3).timeout

	if falhas.is_empty():
		print("PUZZLE_BOTOES_OK: %d verificacoes dos botoes simultaneos e fence_set3." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
