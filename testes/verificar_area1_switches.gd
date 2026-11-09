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


func conjunto_aberto(partes: Array) -> bool:
	for parte in partes:
		if not parte.esta_aberta():
			return false
	return true


func conjunto_fechado(partes: Array) -> bool:
	for parte in partes:
		if not parte.esta_fechada():
			return false
	return true


func rodar() -> void:
	AudioServer.set_bus_mute(0, true)
	var area: Node2D = load("res://cenas/areas/area_1.tscn").instantiate()
	root.add_child(area)
	await quadros()

	var fence3: Fence = area.get_node("objects/fence3")
	var fence4: Fence = area.get_node("objects/fence4")
	var fence_set3: FenceSet = area.get_node("objects/fence_set3")
	var switch2: Node2D = area.get_node("objects/switch2")
	var switch3: Node2D = area.get_node("objects/switch3")
	var switch4: Node2D = area.get_node("objects/switch4")
	var partes: Array = fence_set3.find_children("fence*", "", true, false)

	conferir(partes.size() == 3, "fence_set3 possui tres cercas")
	conferir(fence3.esta_fechada() and fence4.esta_fechada(), "fence3 e fence4 comecam fechadas")
	conferir(conjunto_fechado(partes), "fence_set3 comeca fechado")

	switch2.receber_dano(1, Vector2.ZERO)
	await quadros()
	conferir(switch2.get_state() == &"gold", "switch2 e acionado")
	conferir(fence3.esta_fechada() and fence4.esta_fechada(), "switch2 sozinho mantem fence3 e fence4 fechadas")
	conferir(not conjunto_aberto(partes), "switch2 sozinho mantem fence_set3 fechado")

	switch4.receber_dano(1, Vector2.ZERO)
	await quadros()
	conferir(switch4.get_state() == &"gold", "switch4 e acionado")
	conferir(fence3.esta_fechada() and fence4.esta_fechada(), "switch2 e switch4 mantem fence3 e fence4 fechadas")
	conferir(not conjunto_aberto(partes), "switch2 e switch4 mantem fence_set3 fechado")

	switch3.receber_dano(1, Vector2.ZERO)
	await create_timer(1.5).timeout
	conferir(switch3.get_state() == &"gold", "switch3 e acionado")
	conferir(fence3.esta_aberta(), "fence3 abre com os tres switches")
	conferir(fence4.esta_aberta(), "fence4 abre com os tres switches")
	conferir(conjunto_aberto(partes), "fence_set3 abre com os tres switches")

	area.free()
	await create_timer(0.3).timeout

	if falhas.is_empty():
		print("AREA1_SWITCHES_OK: %d verificacoes dos tres switches e cercas." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
