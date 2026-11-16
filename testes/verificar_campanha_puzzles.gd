extends SceneTree
const TIRO = preload("res://cenas/combate/projetil.tscn")
var verificacoes := 0
var erros := 0

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
	if h.ativa: h.finalizar()

func centro(p: Vector2i) -> Vector2:
	return Vector2(p)*24+Vector2(12,12)

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
			if vistos.has(q) or q.x < 0 or q.y < 0 or q.x >= 36 or q.y >= 26: continue
			vistos[q] = true
			consulta.transform = Transform2D(0,centro(q))
			if current_scene.get_world_2d().direct_space_state.intersect_shape(consulta,1).is_empty():
				fila.append(q)
	return false

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
	disparar(alvo.position+Vector2(0,33),Vector2.UP)
	await esperar(0.25)

func golpear_roda() -> void:
	var roda = current_scene.get_node("MecanismoNico")
	current_scene.nico.position = roda.position+Vector2(-28,0)
	current_scene.nico.olhar_para(Vector2.RIGHT)
	await esperar(0.1)
	conferir(current_scene.nico.iniciar_ataque(),"Nico consegue iniciar um golpe real na trava")
	await esperar(0.65)

func saida_real() -> void:
	var sala = current_scene
	var ponto: Vector2 = sala.get_node("Saida").position
	sala.nico.position = ponto+Vector2(-20,0)
	sala.otto.position = ponto+Vector2(20,0)
	await esperar(0.2)
	conferir(root.get_node("HistoriaDupla").ativa,"A conclusão espera a conversa da dupla")
	fechar_fala()
	await esperar(1.5)

func executar() -> void:
	create_timer(65).timeout.connect(func(): push_error("Tempo limite da campanha"); quit(1))
	change_scene_to_file("res://cenas/screens/start_menu.tscn")
	await scene_changed
	current_scene._on_play_pressed()
	await esperar(1.4)
	conferir(current_scene.scene_file_path.ends_with("entrada_aventura.tscn"),"Jogar abre a apresentação animada")
	current_scene.pular.pressed.emit()
	await esperar(1.0)
	conferir(current_scene.scene_file_path.ends_with("puzzle_01.tscn"),"Jogar abre as celas")
	for dados: Dictionary in preload("res://recursos/mapas_puzzle.gd").FASES.values():
		var moveis_secos := true
		var tochas_secas := true
		for tanque: Rect2i in dados.agua:
			for prop in dados.props:
				moveis_secos = moveis_secos and not tanque.has_point(Vector2i(prop[0],prop[1]))
			for tocha: Vector2i in dados.tochas:
				tochas_secas = tochas_secas and not tanque.has_point(tocha)
		conferir(moveis_secos,"Mobiliário não fica dentro da água")
		conferir(tochas_secas,"Tochas não ficam dentro da água")
	fechar_fala()
	await esperar(0.2)
	conferir(current_scene.nico.position.distance_to(current_scene.otto.position) > 200,"Os protagonistas começam em celas diferentes")
	conferir(caminho_livre(current_scene.nico.position,current_scene.get_node("PlacaNico").position),"Nico alcança sua placa")
	conferir(not caminho_livre(current_scene.otto.position,current_scene.get_node("PlacaOtto").position),"Otto começa preso de verdade")
	conferir(not caminho_livre(current_scene.nico.position,current_scene.get_node("Saida").position),"Não existe atalho até a saída das celas")
	await testar_alvo(0)
	conferir(not current_scene.resolvida,"Tiro sem Nico na placa não liberta Otto")
	current_scene.nico.position = current_scene.get_node("PlacaNico").position
	await esperar(0.1)
	conferir(current_scene.get_node("Alvos/Alvo1").ativo,"Nico revela o alvo de Otto")
	current_scene.nico.position += Vector2(40,0)
	await esperar(0.1)
	conferir(not current_scene.get_node("Alvos/Alvo1").ativo,"Sair da placa recolhe o alvo e permite nova tentativa")
	current_scene.nico.position = current_scene.get_node("PlacaNico").position
	await esperar(0.1)
	await testar_alvo(0)
	conferir(current_scene.resolvida,"Tiro real liberta Otto")
	await esperar(1.3)
	conferir(not current_scene.pronta,"Libertar Otto não resolve a segunda tarefa")
	conferir(caminho_livre(current_scene.otto.position,current_scene.get_node("PlacaOtto").position),"Otto livre pode chegar à sua placa")
	await golpear_roda()
	conferir(not current_scene.roda_ativa,"Golpe sem a ajuda de Otto não abre a última grade")
	current_scene.otto.position = current_scene.get_node("PlacaOtto").position
	await esperar(0.1)
	await golpear_roda()
	conferir(current_scene.roda_ativa,"Nico aciona a trava quando Otto mantém a placa")
	current_scene.otto.position += Vector2(40,0)
	await esperar(2)
	conferir(current_scene.pronta,"A saída permanece aberta quando Otto sai da placa")
	conferir(caminho_livre(current_scene.nico.position,current_scene.get_node("Saida").position),"Caminho físico até a primeira saída")
	await saida_real()
	conferir(current_scene.scene_file_path.ends_with("puzzle_02.tscn"),"Celas levam à cisterna")
	if "--somente-celas" in OS.get_cmdline_user_args():
		print("Celas: %d verificações; %d falhas"%[verificacoes,erros])
		quit(1 if erros > 0 else 0)
		return
	await esperar(0.1)
	fechar_fala()
	for i in 3:
		conferir(caminho_livre(current_scene.nico.position,centro(current_scene.dados.pistas[i])),"Pista %d acessível"%i)
	conferir(not caminho_livre(current_scene.nico.position,current_scene.get_node("Saida").position),"A água impede o atalho antes da ponte")
	await testar_alvo(1)
	conferir(current_scene.progresso == 0,"Os receptores começam desligados")
	await golpear_roda()
	conferir(current_scene.roda_ativa,"Trava real desperta os receptores da cisterna")
	await testar_alvo(1)
	conferir(current_scene.progresso == 0,"É preciso descobrir a pista antes de usar sua resposta")
	for i in 3:
		current_scene.nico.position = centro(current_scene.dados.pistas[i])+Vector2(0,25)
		await esperar(0.1)
	conferir(current_scene.pistas_lidas.size() == 3,"Explorar revela as três pistas no HUD")
	await testar_alvo(2)
	conferir(current_scene.progresso == 0,"Símbolo errado permite tentar de novo")
	await testar_alvo(1)
	conferir(current_scene.progresso == 1,"Triângulo registra o primeiro acerto")
	await testar_alvo(2)
	conferir(current_scene.progresso == 1,"Erro preserva o acerto anterior")
	for indice in [0,2]: await testar_alvo(indice)
	conferir(not current_scene.get_node("BloqueioPonte/shape").disabled,"A ponte permanece bloqueada durante a animação")
	await esperar(2)
	conferir(current_scene.pronta,"Sequência completa prepara a saída")
	conferir(current_scene.get_node("BloqueioPonte/shape").disabled,"A ponte libera passagem só quando termina")
	conferir(caminho_livre(current_scene.nico.position,current_scene.get_node("Saida").position),"Cisterna conectada pela ponte aberta")
	current_scene.nico.position = centro(Vector2i(20,13))
	current_scene.otto.position = centro(Vector2i(20,14))
	Input.action_press("player1_direita")
	Input.action_press("player2_direita")
	await esperar(1.8)
	Input.action_release("player1_direita")
	Input.action_release("player2_direita")
	conferir(current_scene.nico.position.x > 612 and current_scene.otto.position.x > 612,"Os dois atravessam a ponte por movimento real")
	await saida_real()
	conferir(current_scene.scene_file_path.ends_with("area_3.tscn"),"Cisterna leva à fase 3 existente")
	await esperar(0.1)
	fechar_fala()
	conferir(current_scene.fase_historia == 3,"A fase existente conserva seu capítulo")
	current_scene.player1.position = current_scene.button2.position
	current_scene.player2.position = current_scene.button3.position
	await esperar(0.9)
	conferir(current_scene._fences_opened,"Placas da fase existente continuam funcionando")
	var fim = current_scene.get_node("level_end")
	fim._on_body_entered(current_scene.player1)
	fim._on_body_entered(current_scene.player2)
	await esperar(0.1)
	fechar_fala()
	await esperar(1.5)
	conferir(current_scene.scene_file_path.ends_with("puzzle_04.tscn"),"Fase existente leva à aurora")
	await esperar(0.1)
	fechar_fala()
	conferir(caminho_livre(current_scene.nico.position,current_scene.get_node("MecanismoNico").position+Vector2(-24,0)),"Nico alcança a trava de sua ala")
	conferir(caminho_livre(current_scene.otto.position,centro(current_scene.dados.tiro)),"Otto alcança a área de disparo")
	await golpear_roda()
	conferir(current_scene.roda_ativa,"Nico prepara o espelho com um golpe")
	await esperar(0.5)
	conferir(is_equal_approx(current_scene.get_node("Espelho").rotation,-PI/4),"Espelho termina alinhado a 45 graus")
	current_scene.nico.position = current_scene.get_node("PlacaNico").position
	await esperar(0.1)
	await testar_alvo(0)
	conferir(not current_scene.resolvida,"Tiro direto não substitui a cooperação com o espelho")
	current_scene.otto.position = centro(current_scene.dados.tiro)
	disparar(current_scene.otto.position+Vector2(14,0),Vector2.RIGHT,true)
	await esperar(1.3)
	conferir(current_scene.resolvida,"Tiro carregado rebate no espelho real e acerta o alvo")
	await esperar(1.3)
	conferir(not current_scene.pronta,"Porta final espera os dois amigos")
	conferir(caminho_livre(current_scene.otto.position,current_scene.get_node("PlacasFinais").get_child(1).position),"Grade aberta permite o reencontro")
	var placas = current_scene.get_node("PlacasFinais").get_children()
	current_scene.nico.position = placas[0].position
	current_scene.otto.position = placas[1].position
	await esperar(1)
	conferir(current_scene.pronta,"As duas placas finais abrem a porta")
	await saida_real()
	conferir(current_scene.scene_file_path.ends_with("fim_aventura.tscn"),"Campanha termina na conclusão")
	conferir(root.get_node("HistoriaDupla").pontos == 4,"Amizade completa ao escapar")
	print("Campanha redesenhada: %d verificações; %d falhas"%[verificacoes,erros])
	current_scene.queue_free()
	await process_frame
	await esperar(0.15)
	quit(1 if erros > 0 else 0)
