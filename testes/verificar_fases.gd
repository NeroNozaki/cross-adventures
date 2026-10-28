extends SceneTree
var erros: Array[String] = []
var checks: int = 0
const NOMES = ["01_jardim", "02_galeria", "03_oficina", "04_santuario"]
func _initialize() -> void:
	call_deferred("rodar")
func verificar(ok: bool, mensagem: String) -> void:
	checks += 1
	if not ok:
		erros.append(mensagem)
		push_error(mensagem)
func tick(fase: Node2D) -> void:
	fase._physics_process(0.016)
func pausa() -> void:
	await physics_frame
	await physics_frame
	await process_frame
func tiro_falso(elemento: String = "normal", z: int = 0, b: int = 0, carga: bool = false) -> Node2D:
	var p = load("res://cenas/combate/projetil.tscn").instantiate()
	p.elemento = elemento
	p.altura_nivel = z
	p.ricochetes = b
	p.carregado = carga
	return p
func disparo(fase: Node2D, origem: Vector2, dir: Vector2, elemento: String = "normal", z: int = 0, carga: bool = false) -> void:
	var p = tiro_falso(elemento,z,0,carga)
	p.emissor = fase.otto
	p.direcao = dir
	p.position = origem
	fase.add_child(p)
	await create_timer(1.2).timeout
	if is_instance_valid(p):
		p.queue_free()
	await pausa()
func andar_alcancavel(fase: Node2D, inicio: Vector2i, fim: Vector2i) -> bool:
	var fila: Array[Vector2i] = [inicio]
	var vistos: Dictionary = {inicio: true}
	while not fila.is_empty():
		var c: Vector2i = fila.pop_front()
		if c == fim:
			return true
		var z: int = fase.altura_em(Vector2(c)*32+Vector2(16,16))
		for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			for salto in [1,2]:
				var d: Vector2i = c + dir*salto
				if vistos.has(d):
					continue
				var h: int = fase.altura_em(Vector2(d)*32+Vector2(16,16))
				if h < 0 or (h != z and (salto == 2 or (c not in fase.rampas and d not in fase.rampas))):
					continue
				var bloqueado: bool = false
				for parede in fase.dados.paredes:
					var r: Rect2i = Rect2i(parede[0],parede[1],parede[2],parede[3])
					if r.has_point(d) or (salto == 2 and r.has_point(c+dir)):
						bloqueado = true
				if not bloqueado:
					vistos[d] = true
					fila.append(d)
	return false
func rodar() -> void:
	AudioServer.set_bus_mute(0,true)
	for i in range(4):
		var fase: Node2D = load("res://cenas/fases/" + NOMES[i] + ".tscn").instantiate()
		root.add_child(fase)
		current_scene = fase
		await pausa()
		fase.set_physics_process(false)
		for ator in fase.atores:
			ator.set_physics_process(false)
		verificar(fase.dados.numero == i+1, "Ordem da fase")
		verificar(fase.get_node("SoloZ0") is TileMapLayer, "TileMapLayer editavel")
		verificar(not fase.saida.ativo, "Saida inicialmente fechada")
		var lucas = fase.lucas
		var otto = fase.otto
		var obj = fase.get_node("Objetos")
		if i == 0:
			var planta = obj.get_node("DecorInterativa0")
			lucas.position = planta.position + Vector2(0,34)
			lucas.olhar_para(Vector2.UP)
			await pausa()
			verificar(lucas.iniciar_ataque(), "Ataque ao cenario inicia")
			for quadro in range(20):
				await physics_frame
			verificar(planta.esta_morto and planta.collision_layer == 0, "Espada quebra planta sem bloquear sua propria linha de visao")
			var morto_tiro = tiro_falso()
			verificar(planta.receber_projetil(morto_tiro) == "ignorar" and planta.get_node("AreaDano").collision_layer == 0, "Destrocos nao interceptam tiros")
			morto_tiro.free()
			lucas.atacando = false
			lucas.preparo.stop()
			lucas.recarga.stop()
			verificar(fase.altura_em(Vector2(400,656)) == -1, "Vao central real")
			verificar(fase.get_node("SoloZ0").get_cell_source_id(Vector2i(12,20)) == -1, "Vao sem tile")
			var t = tiro_falso("normal",0,1)
			obj.get_node("Cristal").receber_projetil(t)
			verificar(not fase.sinais.get("cristal",false), "Cristal exige parceiro na placa")
			otto.position = obj.get_node("PlacaA").position
			tick(fase)
			verificar(not fase.sinais.get("placa_a",false), "Placa cooperativa exige Lucas")
			otto.position = Vector2(fase.dados.spawns[1][0]*32+16,fase.dados.spawns[1][1]*32+16)
			lucas.position = obj.get_node("PlacaA").position
			tick(fase)
			verificar(fase.sinais.get("placa_a",false), "Placa detecta Lucas")
			await disparo(fase,obj.get_node("EspelhoJardim").position+Vector2(-128,-15),Vector2.RIGHT)
			tick(fase)
			verificar(fase.sinais.get("ponte",false), "Tiro real abre ponte")
			verificar(not fase.ponte_pronta("ponte"),"Ponte aguarda a animação antes de abrir a colisão")
			await create_timer(2.0).timeout
			verificar(fase.altura_em(Vector2(400,656)) == 0, "Colisao da ponte atualizada")
			lucas.position = Vector2(1040,240)
			lucas.altura_nivel = 1
			verificar(fase.tentar_salto(lucas,Vector2.RIGHT), "Salto atravessa vao no mesmo Z")
			var combo_anterior: int = lucas.passo_combo
			verificar(not lucas.iniciar_ataque() and lucas.passo_combo == combo_anterior, "Salto nao consome combo")
			otto.pulando = true
			verificar(otto.disparar() == null and not otto.iniciar_carga(), "Salto impede disparo e carga")
			otto.pulando = false
			fase.mover_personagem(lucas,0.5)
			verificar(not lucas.pulando and lucas.position.distance_to(Vector2(1104,240)) < 0.1, "Pouso correto")
			lucas.position = Vector2(944,240)
			lucas.altura_nivel = 0
			verificar(not fase.tentar_salto(lucas,Vector2.RIGHT), "Salto rejeita altura diferente")
			lucas.position = Vector2(976,368)
			lucas.velocity = Vector2(0,-32)
			fase.mover_personagem(lucas,1)
			verificar(lucas.altura_nivel == 1, "Rampa muda o Z")
			verificar(lucas.get_node("Nome").position.y == -76, "Nome preserva offset acima do heroi elevado")
			lucas.receber_dano(999,Vector2.ZERO)
			await pausa()
			fase.restaurar(lucas)
			verificar(not lucas.esta_morto and lucas.vida_atual == lucas.vida_maxima and lucas.collision_layer == 2 and lucas.position == Vector2(fase.dados.spawns[0][0]*32+16,fase.dados.spawns[0][1]*32+16), "Respawn restaura vida, colisao e posicao")
			t.free()
		elif i == 1:
			var t = tiro_falso()
			obj.get_node("CristalEco").receber_projetil(t)
			verificar(not fase.sinais.get("eco",false), "Eco rejeita tiro direto")
			lucas.position = obj.get_node("PlacaA").position
			tick(fase)
			otto.position = obj.get_node("Espelho").position+Vector2(-92,12)
			otto.mira.atualizar(obj.get_node("Espelho").position+Vector2(1000,-3),0)
			verificar(otto.mira.trajeto.size() >= 3, "Previsao calcula reflexao antes do tiro")
			otto.mira.travada = true
			otto.mira.atualizar(obj.get_node("Espelho").position+Vector2(-92,-1000),0)
			verificar(otto.mira.direcao.distance_to(Vector2.RIGHT) < 0.01, "Tab mantem angulo travado")
			otto.mira.travada = false
			await disparo(fase,obj.get_node("Espelho").position+Vector2(-92,-3),Vector2.RIGHT)
			tick(fase)
			verificar(fase.sinais.get("eco",false), "Reflexao real ativa Eco com parceiro")
			verificar(obj.get_node("Grade").ativo and obj.get_node("Grade").collision_layer == 0, "Grade abre sua colisao")
			t.free()
		else:
			var agua = obj.get_node("AguaCaixa")
			var t = tiro_falso("gelo")
			verificar(agua.receber_projetil(t) == "consumir" and agua.tipo() == "gelo", "Gelo congela agua")
			verificar(not agua.interagir(otto), "Otto nao empurra bloco de Lucas")
			lucas.position = agua.position - Vector2(32,0)
			lucas.frente = Vector2.RIGHT
			verificar(agua.interagir(lucas), "Lucas empurra gelo")
			await create_timer(0.22).timeout
			lucas.position += Vector2(32,0)
			verificar(agua.interagir(lucas), "Segundo empurrao")
			await create_timer(0.22).timeout
			tick(fase)
			verificar(fase.sinais.get("peso",false), "Bloco mantem placa pressionada")
			if i == 2:
				t.elemento = "fogo"
				obj.get_node("GeloBarreira").receber_projetil(t)
				verificar(fase.sinais.get("derreteu",false) and obj.get_node("GeloBarreira").collision_layer == 0, "Fogo abre barreira")
				t.elemento = "normal"
				obj.get_node("Condutor").receber_projetil(t)
				verificar(not fase.sinais.get("energia",false), "Condutor exige choque e ricochete")
				await disparo(fase,obj.get_node("Espelho").position+Vector2(-92,-3),Vector2.RIGHT,"choque")
				verificar(fase.sinais.get("energia",false), "Choque com ricochete real")
				t.elemento = "onda"
				obj.get_node("Bolha").receber_projetil(t)
				verificar(fase.sinais.get("onda",false) and obj.get_node("Bolha").collision_layer == 0, "Onda dissipa bolha")
				var p = fase.get_node("Plataformas/Plataforma0")
				lucas.position = p.position
				lucas.altura_nivel = 1
				var antes: Vector2 = lucas.position
				p.avancar(0.3,fase.atores)
				verificar(lucas.position.distance_to(antes) > 1 and p.contem(lucas.position), "Plataforma transporta passageiro")
			else:
				var chefe = fase.get_node("Personagens/Guardiao")
				var vida: int = chefe.vida_atual
				chefe.receber_dano(999,lucas.position)
				verificar(chefe.vida_atual == vida, "Guardiao protegido pelos tres selos")
				lucas.position = obj.get_node("PlacaA").position
				tick(fase)
				obj.get_node("DecorInterativa1").receber_dano(999,Vector2.ZERO)
				await pausa()
				await disparo(fase,obj.get_node("Espelho").position+Vector2(-92,-3),Vector2.RIGHT)
				verificar(fase.sinais.get("eco",false), "Selo de eco real do santuario")
				t.elemento = "choque"
				t.altura_nivel = 0
				t.carregado = true
				obj.get_node("Nucleo").receber_projetil(t)
				verificar(not fase.sinais.get("nucleo",false), "Nucleo rejeita tiro de outra altura")
				await disparo(fase,obj.get_node("Nucleo").position+Vector2(0,40),Vector2.UP,"choque",1,true)
				tick(fase)
				verificar(fase.sinais.get("nucleo",false) and not chefe.protegido, "Carga de choque elevada libera chefe")
				chefe.receber_dano(999,lucas.position)
				verificar(chefe.esta_morto, "Guardiao vulneravel apos puzzle")
			t.free()
		for ator in fase.atores:
			if ator.equipe == 1:
				ator.tempo_dano = 0
				if not ator.esta_morto:
					ator.receber_dano(999,lucas.position)
		tick(fase)
		verificar(fase.saida.ativo, "Objetivos abrem portal da fase " + str(i+1))
		# Todas as rampas e o portal possuem rota, usando os saltos definidos.
		var inicio: Vector2i=Vector2i(fase.dados.spawns[0][0],fase.dados.spawns[0][1])
		var rota: bool=andar_alcancavel(fase,inicio,fase.celula(fase.saida.position))
		if i==2 and not rota:
			for passo in range(20):
				fase.get_node("Plataformas/Plataforma0").avancar(0.25,fase.atores)
				if andar_alcancavel(fase,inicio,fase.celula(fase.saida.position)):
					rota=true
					break
		verificar(rota,"Rota do inicio ao portal fase "+str(i+1))
		lucas.position = fase.saida.position
		lucas.altura_nivel = fase.saida.altura_nivel
		lucas.pulando = false
		otto.position = Vector2(fase.dados.spawns[1][0]*32+16,fase.dados.spawns[1][1]*32+16)
		otto.altura_nivel = 0
		tick(fase)
		verificar(not fase.concluida, "Portal aguarda os dois jogadores")
		otto.position = fase.saida.position + Vector2(20,0)
		otto.altura_nivel = fase.saida.altura_nivel
		tick(fase)
		verificar(fase.concluida, "Portal reconhece equipe completa")
		# A troca deferida entre fases tambem precisa funcionar sem nos residuais.
		if i < 3:
			await create_timer(0.75).timeout
			await process_frame
			await process_frame
			verificar(current_scene.arquivo_dados.ends_with(NOMES[i+1]+".json"), "Transicao para proxima fase")
			current_scene.queue_free()
		else:
			verificar(fase.mensagem.text.contains("MEDALHA") or fase.mensagem.text.contains("Medalha"), "Final exibe recompensa")
			fase.queue_free()
		await process_frame
		await create_timer(0.2).timeout
	root.get_node("InterfaceAudio").parar()
	await create_timer(0.15).timeout
	if erros.is_empty():
		print("FASES_OK: %d verificacoes de quatro cenas, alturas, salto, cooperacao, elementos, tiros reais, plataforma, chefe, portais e transicoes." % checks)
		quit(0)
	else:
		print("FASES_FALHAS: ", erros)
		quit(1)
