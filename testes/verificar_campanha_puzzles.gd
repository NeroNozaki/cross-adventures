extends SceneTree
const TIRO = preload("res://cenas/combate/projetil.tscn")
var verificacoes := 0
var erros := 0
func caminho_livre(origem: Vector2, destino: Vector2) -> bool:
	var inicio := Vector2i(floori(origem.x/24),floori(origem.y/24))
	var fim := Vector2i(floori(destino.x/24),floori(destino.y/24))
	var fila: Array[Vector2i] = [inicio]
	var vistos := {inicio:true}
	var consulta := PhysicsShapeQueryParameters2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 9
	consulta.shape = forma
	consulta.collision_mask = 1
	var indice := 0
	while indice < fila.size():
		var p := fila[indice]
		indice += 1
		if p == fim: return true
		for direcao: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var q := p+direcao
			if vistos.has(q) or q.x < 0 or q.y < 0 or q.x >= 32 or q.y >= 22: continue
			vistos[q] = true
			consulta.transform = Transform2D(0,Vector2(q)*24+Vector2(12,12))
			if current_scene.get_world_2d().direct_space_state.intersect_shape(consulta,1).is_empty():
				fila.append(q)
	return false
func _initialize() -> void:
	call_deferred("executar")
func conferir(condicao: bool, mensagem: String) -> void:
	verificacoes += 1
	if not condicao:
		erros += 1
		push_error(mensagem)
func esperar(segundos: float) -> void:
	await create_timer(segundos).timeout
func fechar_fala() -> void:
	var h = root.get_node("HistoriaDupla")
	if h.ativa:
		h.finalizar()
func carregar(numero: int) -> void:
	change_scene_to_file("res://cenas/areas/puzzle_%02d.tscn"%numero)
	await scene_changed
	await esperar(0.25)
	fechar_fala()
	await esperar(0.15)
func disparar(origem: Vector2, direcao: Vector2, carregado: bool = false) -> Node:
	var tiro = TIRO.instantiate()
	tiro.emissor = current_scene.otto
	tiro.carregado = carregado
	tiro.raio = 6 if carregado else 4
	tiro.position = origem
	tiro.direcao = direcao
	current_scene.add_child(tiro)
	return tiro
func testar_alvo(indice: int) -> void:
	var alvo = current_scene.get_node("Alvos").get_child(indice)
	var destino: Vector2 = alvo.global_position+Vector2(0,-12)
	disparar(destino+Vector2(0,65),Vector2.UP)
	await esperar(0.35)
func saida_real() -> void:
	var sala = current_scene
	var ponto: Vector2 = sala.get_node("Saida").position
	sala.nico.position = ponto+Vector2(-20,0)
	sala.otto.position = ponto+Vector2(20,0)
	await esperar(0.2)
	conferir(root.get_node("HistoriaDupla").ativa,"A conclusão deve esperar a conversa da dupla")
	fechar_fala()
	await esperar(1.5)
func executar() -> void:
	create_timer(45).timeout.connect(func(): push_error("Tempo limite da campanha"); quit(1))
	change_scene_to_file("res://cenas/screens/start_menu.tscn")
	await scene_changed
	current_scene._on_play_pressed()
	await esperar(1.4)
	conferir(current_scene.scene_file_path.ends_with("puzzle_01.tscn"),"Jogar abre a primeira fase da campanha")
	fechar_fala()
	await esperar(0.15)
	conferir(current_scene.fase_historia == 1,"Capítulo 1")
	conferir(caminho_livre(current_scene.nico.position,current_scene.get_node("PlacaNico").position),"Nico alcança a placa com colisões reais")
	conferir(caminho_livre(current_scene.otto.position,Vector2(396,324)),"Otto alcança a posição de disparo")
	conferir(not caminho_livre(current_scene.otto.position,current_scene.get_node("Saida").position),"A primeira grade realmente impede o atalho")
	await testar_alvo(0)
	conferir(not current_scene.resolvida,"Tiro sem a placa não pode resolver")
	current_scene.otto.position = current_scene.get_node("PlacaNico").position
	await esperar(0.1)
	conferir(not current_scene.placa_ativa,"Otto não substitui Nico nesta placa")
	current_scene.nico.position = current_scene.get_node("PlacaNico").position
	current_scene.otto.position += Vector2(45,0)
	await esperar(0.1)
	conferir(current_scene.placa_ativa,"Nico revela o alvo")
	current_scene.nico.position += Vector2(40,0)
	await esperar(0.1)
	conferir(not current_scene.get_node("Alvos/Alvo1").ativo,"Sair da placa recolhe o alvo")
	current_scene.nico.position = current_scene.get_node("PlacaNico").position
	await esperar(0.1)
	await testar_alvo(0)
	conferir(current_scene.resolvida,"Tiro real resolve o primeiro puzzle")
	await esperar(1.6)
	conferir(current_scene.pronta,"Porta liberada só após a animação")
	conferir(caminho_livre(current_scene.nico.position,current_scene.get_node("Saida").position),"Os dois podem caminhar até a primeira saída")
	current_scene.nico.position += Vector2(40,0)
	await esperar(0.1)
	for parte in current_scene.get_node("Grade").get_children():
		conferir(parte.esta_aberta(),"Grade deve permanecer aberta sem a placa")
	await saida_real()
	conferir(current_scene.scene_file_path.ends_with("puzzle_02.tscn"),"Fase 1 deve levar à fase 2")
	await esperar(0.1)
	fechar_fala()
	conferir(caminho_livre(current_scene.nico.position,current_scene.get_node("PlacaNico").position),"Placa da galeria é acessível")
	conferir(not caminho_livre(current_scene.nico.position,current_scene.get_node("Saida").position),"Não existe atalho pela água da galeria")
	current_scene.nico.position = current_scene.get_node("PlacaNico").position
	await esperar(0.1)
	await testar_alvo(2)
	conferir(current_scene.progresso == 0,"Ordem errada permite recomeçar")
	await testar_alvo(1)
	conferir(current_scene.progresso == 1,"Primeiro símbolo correto")
	await testar_alvo(2)
	conferir(current_scene.progresso == 0,"Erro no meio limpa a sequência")
	for indice in [1,0,2]:
		await testar_alvo(indice)
	await esperar(1.6)
	conferir(current_scene.pronta,"Sequência completa abre ponte e porta")
	conferir(current_scene.get_node("BloqueioPonte/shape").disabled,"Ponte só libera colisão quando termina de subir")
	current_scene.nico.position = Vector2(300,228)
	current_scene.otto.position = Vector2(300,250)
	Input.action_press("player1_direita")
	Input.action_press("player2_direita")
	await esperar(1.8)
	Input.action_release("player1_direita")
	Input.action_release("player2_direita")
	conferir(current_scene.nico.position.x > 456 and current_scene.otto.position.x > 456,"Ambos atravessam fisicamente a ponte")
	await saida_real()
	conferir(current_scene.scene_file_path.ends_with("area_3.tscn"),"Fase 2 leva à masmorra existente")
	await esperar(0.1)
	fechar_fala()
	conferir(current_scene.fase_historia == 3,"Masmorra existente é capítulo 3")
	current_scene.player1.position = current_scene.button2.position
	current_scene.player2.position = current_scene.button3.position
	await esperar(0.9)
	conferir(current_scene._fences_opened,"As duas placas da masmorra existente continuam funcionando")
	var fim = current_scene.get_node("level_end")
	fim._on_body_entered(current_scene.player1)
	fim._on_body_entered(current_scene.player2)
	await esperar(0.1)
	fechar_fala()
	await esperar(1.5)
	conferir(current_scene.scene_file_path.ends_with("puzzle_04.tscn"),"Masmorra existente leva à fase 4")
	await esperar(0.1)
	fechar_fala()
	current_scene.nico.position = current_scene.get_node("PlacaNico").position
	await esperar(0.1)
	await testar_alvo(0)
	conferir(not current_scene.resolvida,"Tiro direto não resolve o desafio de ricochete")
	current_scene.otto.position = Vector2(468,420)
	disparar(Vector2(480,420),Vector2.RIGHT,true)
	await esperar(1.2)
	conferir(current_scene.resolvida,"Tiro carregado real reflete no espelho e acerta o alvo")
	await esperar(1.3)
	conferir(not current_scene.pronta,"Última porta espera as duas placas finais")
	var placas = current_scene.get_node("PlacasFinais").get_children()
	current_scene.nico.position = placas[0].position
	current_scene.otto.position = placas[1].position
	await esperar(1)
	conferir(current_scene.pronta,"Uma placa para cada amigo libera a saída")
	await saida_real()
	conferir(current_scene.scene_file_path.ends_with("fim_aventura.tscn"),"As quatro fases terminam na tela de conclusão")
	conferir(root.get_node("HistoriaDupla").pontos == 4,"A amizade chega a Amigos ao escapar")
	print("Campanha: %d verificações; %d falhas"%[verificacoes,erros])
	current_scene.queue_free()
	await process_frame
	quit(1 if erros > 0 else 0)
