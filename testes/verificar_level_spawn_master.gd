extends SceneTree

var falhas: Array[String] = []
var total: int = 0


func _initialize() -> void:
	create_timer(20.0).timeout.connect(func():
		push_error("Timeout do teste de LevelSpawnMaster")
		quit(2)
	)
	call_deferred("rodar")


func conferir(ok: bool, texto: String) -> void:
	total += 1
	if not ok:
		falhas.append(texto)
		push_error(texto)


func quadros(quantidade: int = 4) -> void:
	for _i in range(quantidade):
		await physics_frame
	await process_frame


func criar_heroi(cena: String, pai: Node, posicao: Vector2) -> Node2D:
	var heroi: Node2D = load(cena).instantiate()
	pai.add_child(heroi)
	heroi.global_position = posicao
	heroi.set_physics_process(false)
	return heroi


func criar_spawn(nome: String, posicao: Vector2, pai: Node) -> LevelSpawn:
	var spawn: LevelSpawn = load("res://cenas/objects/respawn/level_spawn.tscn").instantiate()
	spawn.name = nome
	spawn.team_spacing = 0.0
	spawn.position = posicao
	pai.add_child(spawn)
	return spawn


func rodar() -> void:
	AudioServer.set_bus_mute(0, true)
	var mundo := Node2D.new()
	root.add_child(mundo)
	current_scene = mundo

	var player1 := criar_heroi("res://cenas/personagens/player1.tscn", mundo, Vector2.ZERO)
	var player2 := criar_heroi("res://cenas/personagens/player2.tscn", mundo, Vector2.ZERO)

	var master: LevelSpawnMaster = load("res://cenas/objects/level_specifics/level_spawn_master.tscn").instantiate()
	master.name = "PontosDeEntrada"
	var inicio := criar_spawn("Inicio", Vector2(120, 140), master)
	var chefe := criar_spawn("Chefe", Vector2(720, 360), master)
	master.spawn_ativo = "Chefe"

	var total_inicio := [0]
	var total_chefe := [0]
	inicio.team_spawned.connect(func() -> void: total_inicio[0] += 1)
	chefe.team_spawned.connect(func() -> void: total_chefe[0] += 1)

	mundo.add_child(master)
	await quadros(5)

	conferir(master.obter_spawns().size() == 2, "master encontra os dois LevelSpawn filhos")
	conferir(master.obter_nomes_spawns() == PackedStringArray(["Inicio", "Chefe"]), "master lista os nomes na ordem da cena")
	conferir(master.obter_spawn_ativo() == chefe, "master resolve o spawn ativo pelo nome")
	conferir(player1.global_position.distance_to(chefe.global_position) < 0.1, "spawn ativo posiciona Player1")
	conferir(player2.global_position.distance_to(chefe.global_position) < 0.1, "spawn ativo posiciona Player2")
	conferir(total_inicio[0] == 0, "spawn nao selecionado nao ativa sozinho")
	conferir(total_chefe[0] == 1, "spawn selecionado ativa uma unica vez")

	var propriedade := {"name": &"spawn_ativo", "hint": PROPERTY_HINT_NONE, "hint_string": ""}
	master._validate_property(propriedade)
	conferir(propriedade.hint == PROPERTY_HINT_ENUM, "propriedade spawn_ativo usa lista de opcoes")
	conferir(propriedade.hint_string == "Inicio,Chefe", "lista de opcoes contem os nomes dos spawns")

	conferir(master.definir_spawn_ativo(&"Inicio"), "troca de spawn por nome valido")
	await quadros(3)
	conferir(player1.global_position.distance_to(inicio.global_position) < 0.1, "troca move Player1 para o novo spawn")
	conferir(player2.global_position.distance_to(inicio.global_position) < 0.1, "troca move Player2 para o novo spawn")
	conferir(total_inicio[0] == 1, "novo spawn ativa uma unica vez")
	conferir(total_chefe[0] == 1, "spawn anterior nao reativa na troca")

	conferir(not master.definir_spawn_ativo(&"Inexistente"), "troca recusa nome inexistente")
	await quadros(2)
	conferir(player1.global_position.distance_to(inicio.global_position) < 0.1, "nome invalido preserva o spawn atual")

	var spawn_livre := criar_spawn("Livre", Vector2(940, 880), mundo)
	var total_livre := [0]
	spawn_livre.team_spawned.connect(func() -> void: total_livre[0] += 1)
	await quadros(5)
	conferir(total_livre[0] == 1, "spawn fora do master continua ativando sozinho")
	conferir(player1.global_position.distance_to(spawn_livre.global_position) < 0.1, "spawn sem master mantem o posicionamento automatico")
	conferir(player2.global_position.distance_to(spawn_livre.global_position) < 0.1, "spawn sem master posiciona os dois jogadores")

	mundo.free()
	await create_timer(0.2).timeout

	if falhas.is_empty():
		print("LEVEL_SPAWN_MASTER_OK: %d verificacoes de selecao, troca e compatibilidade." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
