extends SceneTree

var erros: Array[String] = []

func _initialize() -> void:
	call_deferred("_executar")

func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		erros.append(mensagem)
		push_error(mensagem)

func _executar() -> void:
	var cena: PackedScene = load("res://cenas/testes/arena_teste.tscn")
	verificar(cena != null, "Arena deve carregar.")
	if cena == null:
		quit(1)
		return
	var arena: Node2D = cena.instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	var guerreiro: CharacterBody2D = arena.get_node("Personagens/Guerreiro")
	var robo: CharacterBody2D = arena.get_node("Personagens/Robo")
	var cavaleiro: CharacterBody2D = arena.get_node("Personagens/CavaleiroAzul")
	var zumbi: CharacterBody2D = arena.get_node("Personagens/Zumbi")
	for ator in [guerreiro, robo, cavaleiro, zumbi]:
		ator.set_physics_process(false)
		verificar(ator.vida_atual == ator.vida_maxima, "Vida inicial: " + ator.name)
		for acao in ["idle", "walk", "attack", "hurt", "death"]:
			for direcao in ["down", "right", "up", "left"]:
				var nome: StringName = StringName(acao + "_" + direcao)
				var frames: SpriteFrames = ator.get_node("Visual/AnimatedSprite2D").sprite_frames
				verificar(frames.has_animation(nome), "Animacao ausente: " + ator.name + " " + str(nome))
				verificar(frames.get_frame_count(nome) > 0, "Animacao vazia: " + str(nome))
	verificar(guerreiro.controlado and not robo.controlado, "Selecao inicial do Guerreiro.")
	arena._selecionar(1)
	verificar(robo.controlado and not guerreiro.controlado, "Troca para Robo.")
	verificar(guerreiro.lider == robo, "Companheiro recebe lider.")
	arena._selecionar(0)
	guerreiro.position = Vector2(150, 220)
	cavaleiro.position = Vector2(179, 220)
	robo.position = Vector2(176, 220)
	zumbi.position = Vector2(480, 300)
	guerreiro.olhar_para(Vector2.RIGHT)
	await physics_frame
	await physics_frame
	verificar(guerreiro.iniciar_ataque(), "Primeiro ataque deve iniciar.")
	verificar(not guerreiro.iniciar_ataque(), "Recarga deve bloquear segundo ataque.")
	await create_timer(0.35).timeout
	verificar(cavaleiro.vida_atual == cavaleiro.vida_maxima - maxi(1, guerreiro.dano_ataque - cavaleiro.defesa), "Golpe deve aplicar dano com defesa.")
	verificar(robo.vida_atual == robo.vida_maxima, "Aliado nao deve receber fogo amigo.")
	var hp: int = cavaleiro.vida_atual
	cavaleiro.receber_dano(40, guerreiro.global_position)
	verificar(cavaleiro.vida_atual == hp, "Invulnerabilidade bloqueia acerto repetido.")
	await create_timer(0.45).timeout
	cavaleiro.receber_dano(999, guerreiro.global_position)
	await process_frame
	verificar(cavaleiro.esta_morto and cavaleiro.vida_atual == 0, "Dano letal causa morte.")
	verificar(cavaleiro.collision_layer == 0, "Morto deixa de bloquear passagem.")
	guerreiro.position = Vector2(450, 300)
	verificar(zumbi._procurar_alvo() == guerreiro, "Zumbi detecta heroi proximo.")
	guerreiro.receber_dano(999, zumbi.global_position)
	verificar(robo.controlado, "Morte do heroi seleciona sobrevivente.")
	robo.position = Vector2(100, 150)
	verificar(zumbi._procurar_alvo() == null, "IA ignora heroi morto e alvo distante.")
	if erros.is_empty():
		print("RPG_TEST_OK: 4 cenas, 80 animacoes, selecao, lider, ataque, defesa, recarga, invulnerabilidade, equipes, morte e IA.")
	else:
		print("RPG_TEST_FAIL: ", erros)
	arena.queue_free()
	await process_frame
	quit(0 if erros.is_empty() else 1)
