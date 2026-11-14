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


func diferenca_graus(a: Vector2, b: Vector2) -> float:
	return absf(rad_to_deg(wrapf(b.angle() - a.angle(), -PI, PI)))


func mirar(mira, angulo_graus: float) -> Vector2:
	var bruto: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(angulo_graus))
	mira.atualizar(mira.global_position + bruto * 120.0, 0.0)
	return mira.direcao


func rodar() -> void:
	AudioServer.set_bus_mute(0, true)
	var jogador: CharacterBody2D = load("res://cenas/personagens/player2.tscn").instantiate()
	jogador.set_physics_process(false)
	root.add_child(jogador)
	await physics_frame
	await process_frame

	var mira = jogador.get_node("Mira360")
	conferir(is_equal_approx(mira.assistencia_angular_graus, 10.0), "Assistencia angular padrao e de 10 graus")

	for i in range(8):
		var alvo: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / 8.0)
		var direcao: Vector2 = mirar(mira, rad_to_deg(alvo.angle()))
		conferir(diferenca_graus(alvo, direcao) < 0.05, "Mira exata preserva o angulo de %d graus" % (i * 45))

	var perto_horizontal: Vector2 = mirar(mira, 2.0)
	conferir(diferenca_graus(Vector2.RIGHT, perto_horizontal) < 0.5, "Mira a 2 graus e puxada para a horizontal")
	conferir(perto_horizontal.length() > 0.999 and perto_horizontal.length() < 1.001, "Assistencia preserva o comprimento da direcao")

	var perto_diagonal: Vector2 = mirar(mira, 44.0)
	conferir(diferenca_graus(Vector2.RIGHT.rotated(deg_to_rad(45.0)), perto_diagonal) < 0.3, "Mira a 1 grau da diagonal e puxada para 45 graus")

	var nudge_longe: Vector2 = mirar(mira, 98.0)
	var desvio: float = diferenca_graus(Vector2.DOWN, nudge_longe)
	conferir(desvio > 0.5 and desvio < 7.5, "Mira a 8 graus do vertical recebe puxao parcial")

	var perto_negativo: Vector2 = mirar(mira, -3.0)
	conferir(diferenca_graus(Vector2.RIGHT, perto_negativo) < 1.5, "Mira logo abaixo da horizontal tambem e assistida")

	var fora_janela: Vector2 = mirar(mira, 15.0)
	conferir(absf(diferenca_graus(Vector2.RIGHT, fora_janela) - 15.0) < 0.05, "Mira fora da janela permanece livre")

	mira.assistencia_angular_graus = 0.0
	var sem_assistencia: Vector2 = mirar(mira, 2.0)
	conferir(absf(diferenca_graus(Vector2.RIGHT, sem_assistencia) - 2.0) < 0.05, "Assistencia pode ser desativada")
	mira.assistencia_angular_graus = 10.0

	mira.forca_assistencia = 0.0
	var sem_forca: Vector2 = mirar(mira, 2.0)
	conferir(absf(diferenca_graus(Vector2.RIGHT, sem_forca) - 2.0) < 0.05, "Forca zero desativa o puxao")
	mira.forca_assistencia = 1.0

	jogador.free()
	await create_timer(0.2).timeout

	if falhas.is_empty():
		print("MIRA_ASSISTIDA_OK: %d verificacoes de encaixe angular." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
