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
	if cena == null:
		push_error("Arena nao carregou.")
		quit(1)
		return
	var arena: Node2D = cena.instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	var g: CharacterBody2D = arena.get_node("Personagens/Guerreiro")
	var r: CharacterBody2D = arena.get_node("Personagens/Robo")
	var c: CharacterBody2D = arena.get_node("Personagens/CavaleiroAzul")
	var z: CharacterBody2D = arena.get_node("Personagens/Zumbi")
	for ator in [g, r, c, z]:
		verificar(ator.vida_atual == ator.vida_maxima, "Vida inicial: " + ator.name)
		for acao in ["idle", "walk", "attack", "hurt", "death"]:
			for dir in ["down", "right", "up", "left"]:
				var frames: SpriteFrames = ator.get_node("Visual/AnimatedSprite2D").sprite_frames
				verificar(frames.has_animation(acao + "_" + dir), "Animacao: " + ator.name + acao + dir)
	verificar(g.controlado and r.controlado, "Ambos os herois devem receber comandos.")
	verificar(g.prefixo_controle != r.prefixo_controle, "Controles precisam de prefixos separados.")
	var esperado: Dictionary = {"robo_esquerda": KEY_LEFT, "robo_direita": KEY_RIGHT, "robo_cima": KEY_UP, "robo_baixo": KEY_DOWN, "robo_atacar": KEY_ENTER, "guerreiro_defender": KEY_SHIFT}
	for acao in esperado:
		var evento: InputEventKey = InputEventKey.new()
		evento.physical_keycode = esperado[acao]
		verificar(InputMap.event_is_action(evento, acao), "Mapeamento real da tecla: " + acao)
	c.set_physics_process(false)
	z.set_physics_process(false)
	g.position = Vector2(120, 180)
	r.position = Vector2(180, 300)
	Input.action_press("guerreiro_direita")
	Input.action_press("robo_esquerda")
	await create_timer(0.13).timeout
	Input.action_release("guerreiro_direita")
	Input.action_release("robo_esquerda")
	verificar(g.position.x > 125 and r.position.x < 175, "Movimento simultaneo em direcoes independentes.")
	await physics_frame
	var pos_g: Vector2 = g.position
	var pos_r: Vector2 = r.position
	await create_timer(0.12).timeout
	verificar(g.position.distance_to(pos_g) < 0.1 and r.position.distance_to(pos_r) < 0.1, "Sem comando ambos permanecem parados, sem seguir.")
	g.set_physics_process(false)
	r.set_physics_process(false)
	g.position = Vector2(300, 220)
	var direcoes: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	for frente in direcoes:
		g.atualizar_estado(1.0)
		g.recarga.stop()
		g.tempo_dano = 0.0
		g.olhar_para(frente)
		c.position = g.position + frente * 29
		z.position = g.position - frente * 29
		r.position = g.position + frente * 26
		c.invulnerabilidade.stop()
		c.vida_atual = c.vida_maxima
		z.invulnerabilidade.stop()
		z.vida_atual = z.vida_maxima
		await physics_frame
		await physics_frame
		verificar(g.iniciar_ataque(), "Iniciar golpe na direcao: " + str(frente))
		verificar(not g.iniciar_ataque(), "Recarga bloqueia golpe duplo.")
		verificar(g.efeitos.frente_golpe == frente, "Efeito deve seguir a direcao do golpe.")
		await create_timer(0.37).timeout
		verificar(c.vida_atual < c.vida_maxima, "Alvo a frente deve sofrer dano: " + str(frente))
		verificar(z.vida_atual == z.vida_maxima, "Alvo atras nao deve sofrer dano: " + str(frente))
		verificar(r.vida_atual == r.vida_maxima, "Sem fogo amigo.")
	# Escudo: defesa ativa bloqueia a frente, mas nao as costas.
	g.atualizar_estado(1.0)
	g.tempo_dano = 0.0
	g.olhar_para(Vector2.RIGHT)
	g.definir_defesa(true)
	verificar(g.defendendo and not g.iniciar_ataque(), "Escudo impede ataque simultaneo.")
	var hp: int = g.vida_atual
	g.receber_dano(30, g.global_position + Vector2(20, 0))
	verificar(g.vida_atual == hp and g.efeitos.impacto > 0.0, "Bloqueio frontal sem dano e com efeito de impacto.")
	g.receber_dano(30, g.global_position - Vector2(20, 0))
	verificar(g.vida_atual == hp - 26, "Escudo nao protege pelas costas.")
	g.definir_defesa(false)
	r.definir_defesa(true)
	verificar(not r.defendendo, "Robo nao possui escudo do Guerreiro.")
	# A armadura deve permanecer exatamente no ponto da morte.
	c.invulnerabilidade.stop()
	var local_morte: Vector2 = c.position
	c.receber_dano(999, g.global_position)
	await create_timer(0.6).timeout
	verificar(c.esta_morto and c.position == local_morte, "Cavaleiro permanece no local da morte.")
	verificar(c.get_node("ArmaduraCaida").visible and not c.animacao.visible, "Armadura caida substitui o personagem em pe.")
	verificar(c.get_node("ArmaduraCaida/Elmo").position.distance_to(Vector2(-13, -3)) < 0.1, "Queda do elmo terminou.")
	verificar(c.collision_layer == 0, "Armadura nao bloqueia passagem.")
	g.invulnerabilidade.stop()
	g.receber_dano(999, z.global_position)
	verificar(g.esta_morto and r.controlado and r.prefixo_controle == "robo", "Morte nao troca os controles do Robo.")
	if erros.is_empty():
		print("RPG_V2_OK: 4 cenas, 80 animacoes, teclas reais, movimento simultaneo, repouso independente, ataques nas 4 direcoes, equipes, escudo frontal/traseiro e armadura persistente.")
	else:
		print("RPG_V2_FAIL: ", erros)
	arena.queue_free()
	await process_frame
	quit(0 if erros.is_empty() else 1)
