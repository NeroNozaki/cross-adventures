extends SceneTree

var falhas: Array[String] = []
var total: int = 0

const CENA_PLAYER1 := "res://cenas/objects/respawn/level_spawn_player1.tscn"
const CENA_PLAYER2 := "res://cenas/objects/respawn/level_spawn_player2.tscn"
const CENA_COMPARTILHADA := "res://cenas/objects/respawn/level_spawn.tscn"


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


func criar_spawn(cena: String, nome: String, posicao: Vector2, pai: Node) -> LevelSpawn:
	var spawn: LevelSpawn = load(cena).instantiate()
	spawn.name = nome
	spawn.team_spacing = 0.0
	spawn.position = posicao
	pai.add_child(spawn)
	return spawn


func posicionado(heroi: Node2D, spawn: LevelSpawn) -> bool:
	return heroi.global_position.distance_to(spawn.global_position) < 0.1


func rodar() -> void:
	AudioServer.set_bus_mute(0, true)
	var mundo := Node2D.new()
	root.add_child(mundo)
	current_scene = mundo

	var player1 := criar_heroi("res://cenas/personagens/player1.tscn", mundo, Vector2.ZERO)
	var player2 := criar_heroi("res://cenas/personagens/player2.tscn", mundo, Vector2.ZERO)

	var master: LevelSpawnMaster = load("res://cenas/objects/level_specifics/level_spawn_master.tscn").instantiate()
	master.name = "PontosDeEntrada"
	var inicio_player1 := criar_spawn(CENA_PLAYER1, "InicioPlayer1", Vector2(120, 140), master)
	var chefe_player1 := criar_spawn(CENA_PLAYER1, "ChefePlayer1", Vector2(720, 360), master)
	var inicio_player2 := criar_spawn(CENA_PLAYER2, "InicioPlayer2", Vector2(140, 160), master)
	var chefe_player2 := criar_spawn(CENA_PLAYER2, "ChefePlayer2", Vector2(740, 380), master)
	master.spawn_ativo_player1 = "ChefePlayer1"
	master.spawn_ativo_player2 = "ChefePlayer2"

	var total_inicio_player1 := [0]
	var total_chefe_player1 := [0]
	var total_inicio_player2 := [0]
	var total_chefe_player2 := [0]
	inicio_player1.team_spawned.connect(func() -> void: total_inicio_player1[0] += 1)
	chefe_player1.team_spawned.connect(func() -> void: total_chefe_player1[0] += 1)
	inicio_player2.team_spawned.connect(func() -> void: total_inicio_player2[0] += 1)
	chefe_player2.team_spawned.connect(func() -> void: total_chefe_player2[0] += 1)

	mundo.add_child(master)
	await quadros(5)

	conferir(master.obter_spawns().size() == 4, "master encontra os quatro LevelSpawn filhos")
	conferir(master.obter_spawns_player1() == [inicio_player1, chefe_player1], "master separa apenas os spawns de Player1")
	conferir(master.obter_spawns_player2() == [inicio_player2, chefe_player2], "master separa apenas os spawns de Player2")
	conferir(master.obter_nomes_spawns_player1() == PackedStringArray(["InicioPlayer1", "ChefePlayer1"]), "master lista os nomes de Player1 na ordem da cena")
	conferir(master.obter_nomes_spawns_player2() == PackedStringArray(["InicioPlayer2", "ChefePlayer2"]), "master lista os nomes de Player2 na ordem da cena")
	conferir(master.obter_spawn_ativo_player1() == chefe_player1, "master resolve o spawn ativo de Player1 pelo nome")
	conferir(master.obter_spawn_ativo_player2() == chefe_player2, "master resolve o spawn ativo de Player2 pelo nome")
	conferir(posicionado(player1, chefe_player1), "spawn ativo posiciona apenas Player1 no ponto de Player1")
	conferir(posicionado(player2, chefe_player2), "spawn ativo posiciona apenas Player2 no ponto de Player2")
	conferir(not posicionado(player1, inicio_player1), "Player1 nao e movido para o spawn inativo")
	conferir(not posicionado(player2, inicio_player2), "Player2 nao e movido para o spawn inativo")
	conferir(total_inicio_player1[0] == 0 and total_inicio_player2[0] == 0, "spawns nao selecionados nao ativam sozinhos")
	conferir(total_chefe_player1[0] == 1 and total_chefe_player2[0] == 1, "cada spawn selecionado ativa uma unica vez")

	var propriedade_player1 := {"name": &"spawn_ativo_player1", "hint": PROPERTY_HINT_NONE, "hint_string": ""}
	master._validate_property(propriedade_player1)
	conferir(propriedade_player1.hint == PROPERTY_HINT_ENUM, "propriedade spawn_ativo_player1 usa lista de opcoes")
	conferir(propriedade_player1.hint_string == "InicioPlayer1,ChefePlayer1", "lista de Player1 contem apenas os spawns de Player1")
	var propriedade_player2 := {"name": &"spawn_ativo_player2", "hint": PROPERTY_HINT_NONE, "hint_string": ""}
	master._validate_property(propriedade_player2)
	conferir(propriedade_player2.hint == PROPERTY_HINT_ENUM, "propriedade spawn_ativo_player2 usa lista de opcoes")
	conferir(propriedade_player2.hint_string == "InicioPlayer2,ChefePlayer2", "lista de Player2 contem apenas os spawns de Player2")

	conferir(master.definir_spawn_ativo_player1(&"InicioPlayer1"), "troca de spawn de Player1 por nome valido")
	await quadros(3)
	conferir(posicionado(player1, inicio_player1), "troca move Player1 para o novo spawn")
	conferir(posicionado(player2, chefe_player2), "troca de Player1 preserva o spawn de Player2")
	conferir(total_inicio_player1[0] == 1 and total_chefe_player2[0] == 1, "troca de Player1 ativa apenas o novo spawn de Player1")

	conferir(master.definir_spawn_ativo_player2(&"InicioPlayer2"), "troca de spawn de Player2 por nome valido")
	await quadros(3)
	conferir(posicionado(player1, inicio_player1), "troca de Player2 preserva o spawn de Player1")
	conferir(posicionado(player2, inicio_player2), "troca move Player2 para o novo spawn")
	conferir(total_inicio_player2[0] == 1 and total_inicio_player1[0] == 1, "troca de Player2 ativa apenas o novo spawn de Player2")

	conferir(not master.definir_spawn_ativo_player1(&"InicioPlayer2"), "campo de Player1 recusa spawn de Player2")
	conferir(not master.definir_spawn_ativo_player2(&"InicioPlayer1"), "campo de Player2 recusa spawn de Player1")
	conferir(not master.definir_spawn_ativo_player1(&"Inexistente"), "troca de Player1 recusa nome inexistente")
	await quadros(2)
	conferir(posicionado(player1, inicio_player1) and posicionado(player2, inicio_player2), "nomes invalidos preservam os spawns atuais")

	var master_padrao: LevelSpawnMaster = load("res://cenas/objects/level_specifics/level_spawn_master.tscn").instantiate()
	var padrao_player1 := criar_spawn(CENA_PLAYER1, "PadraoPlayer1", Vector2(940, 880), master_padrao)
	var padrao_player2 := criar_spawn(CENA_PLAYER2, "PadraoPlayer2", Vector2(960, 900), master_padrao)
	mundo.add_child(master_padrao)
	await quadros(4)
	conferir(posicionado(player1, padrao_player1), "campo vazio usa o primeiro spawn de Player1")
	conferir(posicionado(player2, padrao_player2), "campo vazio usa o primeiro spawn de Player2")

	var spawn_player1_livre := criar_spawn(CENA_PLAYER1, "Player1Livre", Vector2(1080, 1040), mundo)
	await quadros(4)
	conferir(posicionado(player1, spawn_player1_livre), "LevelSpawnPlayer1 fora do master ativa sozinho")
	conferir(posicionado(player2, padrao_player2), "LevelSpawnPlayer1 fora do master nao move Player2")

	var spawn_compartilhado := criar_spawn(CENA_COMPARTILHADA, "Compartilhado", Vector2(1200, 1160), mundo)
	await quadros(4)
	conferir(posicionado(player1, spawn_compartilhado), "LevelSpawn antigo continua posicionando Player1")
	conferir(posicionado(player2, spawn_compartilhado), "LevelSpawn antigo continua posicionando Player2")

	mundo.free()
	await create_timer(0.2).timeout

	if falhas.is_empty():
		print("LEVEL_SPAWN_MASTER_OK: %d verificacoes de grupos independentes, troca e compatibilidade." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
