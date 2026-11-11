extends SceneTree

var erros: Array[String] = []
var contagem_checks: int = 0
var arena: Node2D
var g: CharacterBody2D
var r: CharacterBody2D
var c: CharacterBody2D
var z: CharacterBody2D

func _initialize() -> void:
	create_timer(35.0).timeout.connect(func(): push_error("Timeout dos testes"); quit(2))
	call_deferred("_executar")

func verificar(condicao: bool, descricao: String) -> void:
	contagem_checks += 1
	if not condicao:
		erros.append(descricao)
		push_error(descricao)

func comprimento_caminho(pontos: PackedVector2Array) -> float:
	var total: float = 0.0
	for i in range(1, pontos.size()):
		total += pontos[i - 1].distance_to(pontos[i])
	return total

func limpar_tiros() -> void:
	for tiro in get_nodes_in_group("projeteis"):
		tiro.queue_free()
	await physics_frame

func esperar_combo(passo: int) -> void:
	for quadro in range(90):
		await physics_frame
		if g.passo_combo == passo:
			return

func preparar_player1() -> void:
	g.set_physics_process(false)
	g.atacando = false
	g.recarga.stop()
	g.preparo.stop()
	g.invulnerabilidade.stop()
	g.tempo_dano = 0.0
	g.buffer_ataque = 0.0
	g.restante_combo = 0.0
	g.passo_combo = 0
	g.impulso = Vector2.ZERO
	g.definir_defesa(false)

func tiro_para(alvo: Vector2, forte: bool = false) -> Node2D:
	r.recarga.stop()
	r.tempo_dano = 0.0
	r.mira.atualizar(alvo, 0.0)
	return r.disparar(forte)

func _executar() -> void:
	arena = load("res://cenas/testes/arena_teste.tscn").instantiate()
	arena.set_process_unhandled_input(false)
	root.add_child(arena)
	current_scene = arena
	await process_frame
	g = arena.get_node("Personagens/Player1")
	r = arena.get_node("Personagens/Player2")
	c = arena.get_node("Personagens/CavaleiroAzul")
	z = arena.get_node("Personagens/Zumbi")
	for ator in [g, r, c, z]:
		ator.set_physics_process(false)
	c.position = Vector2(520, 340)
	z.position = Vector2(565, 340)
	# Tres animacoes diferentes para cada direcao, sem perder a orientacao.
	var clips: SpriteFrames = g.animacao.sprite_frames
	for d in ["left", "right", "up", "down"]:
		for passo in range(1, 4):
			var nome: StringName = StringName("combo_%d_%s" % [passo, d])
			verificar(clips.has_animation(nome) and clips.get_frame_count(nome) > 0, "Clip de combo: " + str(nome))
	preparar_player1()
	g.position = Vector2(150, 180)
	g.set_physics_process(true)
	var golpes_cedo: Array[int] = []
	var contar_golpe_cedo := func(passo: int) -> void: golpes_cedo.append(passo)
	g.golpe_combo.connect(contar_golpe_cedo)
	g.iniciar_ataque()
	g.iniciar_ataque()
	g.iniciar_ataque()
	await create_timer(0.8).timeout
	g.golpe_combo.disconnect(contar_golpe_cedo)
	verificar(golpes_cedo == [1], "Comandos antes do primeiro golpe nao enfileiram ataque extra.")
	preparar_player1()
	g.position = Vector2(150, 180)
	g.set_physics_process(true)
	g.iniciar_ataque()
	var clip1: StringName = g.animacao.animation
	await create_timer(0.16).timeout
	g.iniciar_ataque()
	await esperar_combo(2)
	verificar(g.passo_combo == 2 and g.animacao.animation != clip1, "Comando depois do primeiro golpe encadeia o segundo com outro clip.")
	await create_timer(0.16).timeout
	g.iniciar_ataque()
	await esperar_combo(3)
	verificar(g.passo_combo == 3 and g.obter_dano_ataque() > g.dano_ataque, "Terceiro golpe usa estocada e mais dano.")
	await create_timer(1.2).timeout
	g.iniciar_ataque()
	verificar(g.passo_combo == 1, "Pausa entre comandos reinicia o combo.")
	preparar_player1()
	g.set_physics_process(true)
	Input.action_press("player1_atacar")
	await create_timer(0.8).timeout
	Input.action_release("player1_atacar")
	verificar(g.passo_combo == 1, "Segurar ataque nao encadeia o combo automaticamente.")
	preparar_player1()
	g.position = Vector2(150, 180)
	g.set_physics_process(true)
	var golpes_spam: Array[int] = []
	var contar_golpe := func(passo: int) -> void: golpes_spam.append(passo)
	g.golpe_combo.connect(contar_golpe)
	g.iniciar_ataque()
	for quadro in range(300):
		if g.atacando:
			g.iniciar_ataque()
		await physics_frame
		if golpes_spam.size() >= 4:
			break
	await create_timer(0.2).timeout
	g.golpe_combo.disconnect(contar_golpe)
	verificar(golpes_spam.slice(0, 4) == [1, 2, 3, 1], "Terceiro golpe aceita buffer e reinicia o combo.")
	preparar_player1()
	g.position = Vector2(150, 180)
	g.olhar_para(Vector2.RIGHT)
	g.set_physics_process(true)
	var x_antes_escudo: float = g.position.x
	Input.action_press("player1_defender")
	Input.action_press("player1_esquerda")
	for quadro in range(8):
		await physics_frame
	var defendeu_recuando: bool = g.defendendo
	var direcao_escudo: String = g.direcao
	var frente_escudo: Vector2 = g.frente
	var clip_escudo: StringName = g.animacao.animation
	Input.action_release("player1_esquerda")
	Input.action_release("player1_defender")
	g.set_physics_process(false)
	verificar(defendeu_recuando and direcao_escudo == "right" and frente_escudo == Vector2.RIGHT and clip_escudo == &"walk_right" and g.position.x < x_antes_escudo, "Escudo mantem a direcao e recua de costas.")
	preparar_player1()
	# Mira em oito angulos, independente da direcao da caminhada.
	for i in range(8):
		var dir: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / 8.0)
		r.mira.atualizar(r.mira.global_position + dir * 100.0, 0.0)
		verificar(r.mira.direcao.dot(dir) > 0.999, "Mira 360 graus: " + str(i))
	verificar(not r.orientar_pelo_movimento, "Movimento nao substitui a direcao da mira.")
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	verificar(InputMap.event_is_action(mouse, "player2_atacar") and not InputMap.event_is_action(mouse, "player1_atacar"), "Clique esquerdo dispara apenas com Player2.")
	mouse.button_index = MOUSE_BUTTON_RIGHT
	verificar(InputMap.event_is_action(mouse, "player2_dash") and not InputMap.event_is_action(mouse, "player2_atacar") and not InputMap.event_is_action(mouse, "player1_atacar"), "Clique direito aciona apenas o dash de Player2.")
	# Carga curta versus carga completa.
	r.position = Vector2(150, 260)
	r.recarga.stop()
	verificar(r.iniciar_carga(), "Iniciar carga disponivel.")
	r.tempo_carga = 0.1
	var simples: Node2D = r.liberar_carga()
	verificar(simples != null and not simples.carregado and simples.raio == 4.0 and simples.max_ricochetes == 0, "Clique curto gera tiro simples sem ricochete.")
	verificar(not r.iniciar_carga(), "Recarga impede preparar outro disparo.")
	await limpar_tiros()
	r.recarga.stop()
	r.iniciar_carga()
	r.tempo_carga = r.tempo_carga_total
	var forte: Node2D = r.liberar_carga()
	verificar(forte != null and forte.carregado and forte.raio > 4.0 and forte.dano > r.dano_ataque and forte.max_ricochetes > 0, "Segurar e soltar gera esfera maior, mais forte e com ricochete.")
	await limpar_tiros()
	r.recarga.stop()
	r.iniciar_carga()
	r._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	verificar(not r.carregando and r.liberar_carga() == null, "Perda de foco cancela carga sem tiro fantasma.")
	# Protagonistas atravessam um ao outro sem prender os controles.
	g.position = Vector2(200, 270)
	r.position = Vector2(260, 270)
	g.set_physics_process(true)
	r.set_physics_process(true)
	Input.action_press("player1_direita")
	Input.action_press("player2_esquerda")
	await create_timer(0.45).timeout
	Input.action_release("player1_direita")
	Input.action_release("player2_esquerda")
	g.set_physics_process(false)
	r.set_physics_process(false)
	verificar(g.position.x > r.position.x, "Os jogadores nao ficam presos um ao outro.")
	preparar_player1()
	# Interrupcao de golpe ao sofrer dano e bloqueio de golpe por parede.
	g.position = Vector2(300, 220)
	c.position = Vector2(329, 220)
	c.invulnerabilidade.stop()
	var vida_c: int = c.vida_atual
	g.olhar_para(Vector2.RIGHT)
	await physics_frame
	await physics_frame
	g.iniciar_ataque()
	g.iniciar_ataque()
	g.receber_dano(10, Vector2(280, 220))
	await create_timer(0.22).timeout
	verificar(c.vida_atual == vida_c and not g.atacando and g.buffer_ataque == 0.0, "Dano interrompe o preparo e o ataque enfileirado.")
	var parede: StaticBody2D = StaticBody2D.new()
	parede.collision_layer = 1
	parede.collision_mask = 0
	var forma: RectangleShape2D = RectangleShape2D.new()
	forma.size = Vector2(4, 60)
	var colisao: CollisionShape2D = CollisionShape2D.new()
	colisao.shape = forma
	parede.add_child(colisao)
	arena.add_child(parede)
	parede.position = Vector2(315, 220)
	await physics_frame
	await physics_frame
	preparar_player1()
	g.olhar_para(Vector2.RIGHT)
	g.iniciar_ataque()
	await create_timer(0.22).timeout
	verificar(c.vida_atual == vida_c, "Espada nao causa dano atraves da parede.")
	r.position = Vector2(280, 235)
	var rapido: Node2D = tiro_para(Vector2(500, 220))
	rapido.velocidade = 2000.0
	await create_timer(0.055).timeout
	verificar(not is_instance_valid(rapido) and c.vida_atual == vida_c, "Tiro simples para na parede fina em alta velocidade.")
	r.mira.travada = false
	r.mira.atualizar(Vector2(320, 220), 0.0)
	var trajeto_perto: PackedVector2Array = r.mira.trajeto.duplicate()
	r.mira.atualizar(Vector2(1000, 220), 0.0)
	var trajeto_longe: PackedVector2Array = r.mira.trajeto.duplicate()
	verificar(trajeto_perto == trajeto_longe, "Mira tem comprimento fixo independente da distancia do cursor.")
	verificar(absf(r.mira.comprimento - r.mira.comprimento_maximo) < 0.01, "Mira usa sempre o comprimento fixo configurado.")
	var mira_simples: float = comprimento_caminho(r.mira.trajeto)
	verificar(mira_simples > 10.0 and mira_simples < r.mira.comprimento_maximo - 1.0, "Previsao simples para na primeira parede.")
	r.mira.atualizar(Vector2(1000, 220), 1.0)
	var mira_carregada: float = comprimento_caminho(r.mira.trajeto)
	verificar(r.mira.trajeto.size() >= 3 and mira_carregada > r.mira.comprimento_maximo - 1.0 and mira_carregada <= r.mira.comprimento_maximo + 0.01, "Previsao carregada ricocheteia sem exceder o comprimento fixo.")
	await limpar_tiros()
	parede.queue_free()
	await physics_frame
	# Bala passa pelo aliado e acerta a area do inimigo, nao somente os pes.
	g.position = Vector2(170, 230)
	r.position = Vector2(100, 230)
	c.position = Vector2(230, 225)
	c.invulnerabilidade.stop()
	var vida_g: int = g.vida_atual
	var bala: Node2D = tiro_para(c.get_node("AreaDano").global_position)
	await create_timer(0.48).timeout
	verificar(c.vida_atual < vida_c and g.vida_atual == vida_g and not is_instance_valid(bala), "Tiro acerta inimigo, ignora aliado e desaparece no acerto.")
	# Cinco ricochetes reais; quinto encerra a esfera.
	c.get_node("AreaDano").collision_layer = 0
	z.get_node("AreaDano").collision_layer = 0
	r.position = Vector2(300, 230)
	var rebatida: Node2D = tiro_para(Vector2(500, 310), true)
	rebatida.velocidade = 2000.0
	var ricochetes: Array[int] = []
	rebatida.ricocheteou.connect(func(n: int): ricochetes.append(n))
	await create_timer(1.6).timeout
	verificar(ricochetes == [1, 2, 3, 4, 5] and not is_instance_valid(rebatida), "Exatamente cinco contatos com parede antes de apagar.")
	# Esfera carregada percorre a arena com raio e velocidade reais.
	r.position = Vector2(300, 230)
	var grande_rebatida: Node2D = tiro_para(Vector2(500, 310), true)
	var ricochetes_grande: Array[int] = []
	grande_rebatida.ricocheteou.connect(func(n: int): ricochetes_grande.append(n))
	for quadro in range(600):
		await physics_frame
		if not is_instance_valid(grande_rebatida):
			break
	verificar(ricochetes_grande == [1, 2, 3, 4, 5] and not is_instance_valid(grande_rebatida), "Esfera carregada tambem desaparece no quinto ricochete.")
	# Quinas nao consomem todos os ricochetes no mesmo contato.
	r.position = Vector2(600, 125)
	var quina: Node2D = tiro_para(Vector2(650, 60), true)
	quina.velocidade = 800.0
	await create_timer(0.09).timeout
	verificar(is_instance_valid(quina) and quina.ricochetes >= 1 and quina.ricochetes <= 2, "Quina reflete sem contar repetidamente a mesma superficie.")
	await limpar_tiros()
	# Disparo perto da borda superior nao nasce fora do cenario.
	r.position = Vector2(110, 105)
	var perto_parede: Node2D = tiro_para(Vector2(110, 0), true)
	await create_timer(0.1).timeout
	verificar(is_instance_valid(perto_parede) and perto_parede.global_position.y >= 100.0 and perto_parede.ricochetes <= 1, "Origem segura evita nascer dentro ou do lado externo da parede.")
	await limpar_tiros()
	# Vida maxima tambem limita tiros lancados em mapas abertos.
	r.position = Vector2(300, 220)
	var expirando: Node2D = tiro_para(Vector2(500, 220))
	expirando.tempo_de_vida = 0.03
	await create_timer(0.08).timeout
	verificar(not is_instance_valid(expirando), "Tempo de vida elimina esfera sem cenario de ricochete.")
	# Dano cancela carga; morte remove tiros em voo e nao deixa novos ataques.
	r.recarga.stop()
	r.iniciar_carga()
	r.invulnerabilidade.stop()
	r.receber_dano(10, Vector2.ZERO)
	verificar(not r.carregando and r.liberar_carga() == null, "Dano cancela a carga e nao dispara ao soltar.")
	r.tempo_dano = 0.0
	var ultimo: Node2D = tiro_para(Vector2(500, 200))
	r.invulnerabilidade.stop()
	r.receber_dano(999, Vector2.ZERO)
	await create_timer(0.05).timeout
	verificar(not is_instance_valid(ultimo) and r.disparar() == null and not r.mira.visible, "Morte encerra tiros, mira e entrada de novos disparos.")
	# Reinicio limpa esferas e recria o estado dos personagens.
	var teste_tiro: Node2D = load("res://cenas/combate/projetil.tscn").instantiate()
	teste_tiro.emissor = g
	arena.add_child(teste_tiro)
	teste_tiro.global_position = Vector2(300, 200)
	var resultado: Error = reload_current_scene()
	await process_frame
	await process_frame
	arena = current_scene
	verificar(resultado == OK and arena != null and get_nodes_in_group("projeteis").is_empty(), "Reiniciar limpa os tiros da cena anterior.")
	verificar(arena.get_node("Personagens/Player2").vida_atual == 95 and arena.get_node("Personagens/Player1").vida_atual == 120, "Reiniciar restaura os personagens.")
	if erros.is_empty():
		print("COMBO_MIRA_OK: ", contagem_checks, " verificacoes de combo, buffer, mira, carga, colisao continua, equipes, paredes, quinas, cinco ricochetes, dano e morte.")
	else:
		print("COMBO_MIRA_FAIL: ", erros)
	arena.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit(0 if erros.is_empty() else 1)
