extends SceneTree

var erros: Array[String] = []
var eventos: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_executar")

func verificar(condicao: bool, descricao: String) -> void:
	if not condicao:
		erros.append(descricao)
		push_error(descricao)

func _registrar(evento: StringName, arquivo: String, ator: StringName) -> void:
	eventos.append({"ator": ator, "evento": evento, "arquivo": arquivo})

func contar(ator: StringName, evento: StringName) -> int:
	var total: int = 0
	for registro in eventos:
		if registro.ator == ator and registro.evento == evento:
			total += 1
	return total

func _executar() -> void:
	for bus in ["SFX", "Passos", "Combate"]:
		verificar(AudioServer.get_bus_index(bus) >= 0, "Bus de audio: " + bus)
	var arena: Node2D = load("res://cenas/testes/arena_teste.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	# A primeira carga pode consumir o delta do frame de inicialização.
	# Só medir os comandos depois que os atores participaram da física.
	await physics_frame
	await physics_frame
	await process_frame
	var g: CharacterBody2D = arena.get_node("Personagens/Guerreiro")
	var r: CharacterBody2D = arena.get_node("Personagens/Robo")
	var c: CharacterBody2D = arena.get_node("Personagens/CavaleiroAzul")
	var z: CharacterBody2D = arena.get_node("Personagens/Zumbi")
	var todos: Array[CharacterBody2D] = [g, r, c, z]
	for ator in todos:
		ator.audio.som_reproduzido.connect(_registrar.bind(ator.name))
		verificar(ator.audio.perfil != null, "Perfil: " + ator.name)
		for acao in [&"passo", &"ataque", &"acerto", &"dano", &"morte"]:
			var clipes: Array[AudioStream] = ator.audio.perfil.clipes(acao)
			verificar(not clipes.is_empty(), "Clipes de " + str(acao) + ": " + ator.name)
			for clipe in clipes:
				verificar(clipe.get_length() > 0.0, "Audio deve ter duracao: " + clipe.resource_path)
				if clipe is AudioStreamOggVorbis:
					verificar(not clipe.loop, "Efeito nao deve ficar em loop: " + clipe.resource_path)
	c.set_physics_process(false)
	z.set_physics_process(false)
	g.position = Vector2(100, 180)
	r.position = Vector2(150, 300)
	Input.action_press("guerreiro_direita")
	Input.action_press("robo_direita")
	# Os passos dependem da distância simulada, não do custo de um frame de renderização.
	for quadro in range(30):
		await physics_frame
	Input.action_release("guerreiro_direita")
	Input.action_release("robo_direita")
	await physics_frame
	verificar(contar(g.name, &"passo") >= 1 and contar(r.name, &"passo") >= 1, "Os dois jogadores produzem passos ao se deslocar.")
	g.set_physics_process(false)
	r.set_physics_process(false)
	var passos_antes: int = contar(g.name, &"passo")
	g.audio.registrar_movimento(100.0, false)
	g.audio.registrar_movimento(0.0, true)
	await create_timer(0.1).timeout
	verificar(contar(g.name, &"passo") == passos_antes, "Parado, empurrando parede ou sem caminhar nao gera passos.")
	for ator in [c, z]:
		ator.audio.registrar_movimento(25.0, true)
		verificar(contar(ator.name, &"passo") == 1, "Passo de vilao: " + ator.name)
	# Golpe no vazio: emite ataque, mas nao emite acerto.
	g.position = Vector2(120, 220)
	r.position = Vector2(100, 320)
	c.position = Vector2(440, 200)
	z.position = Vector2(500, 300)
	g.olhar_para(Vector2.LEFT)
	g.iniciar_ataque()
	g.iniciar_ataque()
	await create_timer(0.3).timeout
	verificar(contar(g.name, &"ataque") == 1, "Ataque so toca quando aceito pela recarga.")
	verificar(contar(g.name, &"acerto") == 0, "Golpe no vazio nao toca acerto.")
	# Golpe real: tanto o atacante quanto o alvo recebem o evento correto.
	g.atualizar_estado(1.0)
	g.recarga.stop()
	g.position = Vector2(300, 220)
	c.position = Vector2(329, 220)
	g.olhar_para(Vector2.RIGHT)
	await physics_frame
	await physics_frame
	g.iniciar_ataque()
	await create_timer(0.3).timeout
	verificar(contar(g.name, &"acerto") == 1 and contar(c.name, &"dano") == 1, "Acerto real e dano metalico do alvo.")
	# Bloqueio nao se confunde com dano, nem repete o erguer a cada frame.
	g.atualizar_estado(1.0)
	g.definir_defesa(true)
	g.definir_defesa(true)
	var hp: int = g.vida_atual
	g.receber_dano(25, g.global_position + Vector2(20, 0))
	verificar(contar(g.name, &"defesa") == 1, "Erguer escudo toca apenas uma vez por ativacao.")
	verificar(contar(g.name, &"bloqueio") == 1 and contar(g.name, &"dano") == 0 and g.vida_atual == hp, "Bloqueio frontal toca metal sem som de ferimento.")
	g.receber_dano(25, g.global_position - Vector2(20, 0))
	g.receber_dano(25, g.global_position - Vector2(20, 0))
	verificar(contar(g.name, &"dano") == 1, "Dano toca uma vez; invulnerabilidade rejeita repeticao.")
	# Ataque, dano e morte dos demais personagens.
	for ator in [r, c, z]:
		ator.atualizar_estado(1.0)
		ator.recarga.stop()
		ator.tempo_dano = 0.0
		ator.iniciar_ataque()
		verificar(contar(ator.name, &"ataque") >= 1, "Ataque sonoro de " + ator.name)
		ator.invulnerabilidade.stop()
		ator.receber_dano(10, Vector2.ZERO)
		verificar(contar(ator.name, &"dano") >= 1, "Dano sonoro de " + ator.name)
	for ator in todos:
		ator.invulnerabilidade.stop()
		ator.receber_dano(999, Vector2.ZERO)
		ator.receber_dano(999, Vector2.ZERO)
		ator.audio.tocar(&"ataque")
		verificar(ator.audio.morto and not ator.audio.passos_player.playing, "Morte interrompe passos: " + ator.name)
	verificar(contar(c.name, &"morte") == 0, "Som da armadura espera a queda.")
	await create_timer(0.35).timeout
	for ator in todos:
		verificar(contar(ator.name, &"morte") == 1, "Som de morte unico: " + ator.name)
	var sfx: int = AudioServer.get_bus_index("SFX")
	var tecla: InputEventAction = InputEventAction.new()
	tecla.action = "alternar_audio"
	tecla.pressed = true
	arena._unhandled_input(tecla)
	verificar(AudioServer.is_bus_mute(sfx), "M silencia SFX.")
	arena._unhandled_input(tecla)
	verificar(not AudioServer.is_bus_mute(sfx), "M reativa SFX.")
	if erros.is_empty():
		print("AUDIO_OK: 4 perfis, clipes decodificados, buses, passos por deslocamento, ataques validos, acertos confirmados, bloqueio, dano, morte unica, queda sincronizada e mute.")
	else:
		print("AUDIO_FAIL: ", erros)
	arena.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if erros.is_empty() else 1)
