extends SceneTree
var falhas: Array[String]=[]
var checks: int=0
var passos: Dictionary={}
func registrar_passo(evento: StringName,_arquivo: String,ator: StringName) -> void:
	if evento == &"passo": passos[ator]=int(passos.get(ator,0))+1
var f: Node2D
func _initialize() -> void: call_deferred("rodar")
func conferir(ok: bool,t: String) -> void:
	checks+=1
	if not ok: falhas.append(t); push_error(t)
func pausa() -> void:
	await physics_frame
	await physics_frame
func acao(id: String,pressionada: bool) -> void:
	var e: InputEventAction=InputEventAction.new()
	e.action=id
	e.pressed=pressionada
	Input.parse_input_event(e)
func soltar(prefixo: String) -> void:
	for d in ["esquerda","direita","cima","baixo"]: Input.action_release(prefixo+"_"+d)
func andar(ator: CharacterBody2D,destino: Vector2) -> bool:
	var prefixo: String="guerreiro" if ator==f.lucas else "robo"
	if ator.has_meta("rota_cenario"): ator.remove_meta("rota_cenario")
	for quadro in range(2400):
		if f.concluida:
			soltar(prefixo)
			return true
		if ator.global_position.distance_to(destino)<7:
			soltar(prefixo)
			await pausa()
			return true
		var dir: Vector2=f.direcao_ia(ator,destino)
		soltar(prefixo)
		if absf(dir.x)>absf(dir.y): Input.action_press(prefixo+("_direita" if dir.x>0 else "_esquerda"))
		elif dir.length_squared()>0.01: Input.action_press(prefixo+("_baixo" if dir.y>0 else "_cima"))
		await physics_frame
	soltar(prefixo)
	print("ROTA_FALHOU: ",ator.name," ",ator.position," -> ",destino)
	return false
func rodar() -> void:
	AudioServer.set_bus_mute(0,true)
	Engine.time_scale=3.0
	f=load("res://cenas/fases/01_jardim.tscn").instantiate()
	root.add_child(f)
	current_scene=f
	await pausa()
	# Inimigos são testados com IA/combate pelas suítes existentes; aqui isolamos o percurso real.
	for ator in f.atores:
		if ator.equipe==1: ator.set_physics_process(false)
	var lucas: CharacterBody2D=f.lucas
	var otto: CharacterBody2D=f.otto
	for heroi in [lucas,otto]: heroi.audio.som_reproduzido.connect(registrar_passo.bind(heroi.name))
	var placa: Node2D=f.get_node("Objetos/PlacaA")
	var cristal: Node2D=f.get_node("Objetos/Cristal")
	conferir(cristal.position.y<11*32 and placa.position.y>17*32,"Cristal na sala superior e placa na sala inferior")
	conferir(await andar(lucas,placa.position),"Lucas chega à placa usando WASD, sem teleporte")
	conferir(await andar(otto,Vector2(176,272)),"Otto sobe pelo corredor e chega à posição de tiro na sala norte usando setas")
	await pausa()
	conferir(f.sinais.get("placa_a",false),"Lucas parado mantém a placa durante o comando de Otto")
	otto.mira.travada=true
	otto.mira.direcao=Vector2.RIGHT
	acao("robo_atacar",true)
	await pausa()
	acao("robo_atacar",false)
	await create_timer(0.9).timeout
	conferir(not f.ponte_pronta("ponte"),"Ponte ainda está subindo e não libera o chão antes da hora")
	await create_timer(2.0).timeout
	conferir(f.sinais.get("ponte",false),"Tiro real de Otto reflete no espelho e abre a ponte")
	conferir(await andar(lucas,Vector2(560,656)),"Lucas atravessa a ponte com colisão real")
	conferir(await andar(otto,Vector2(528,656)),"Otto atravessa a mesma ponte sem exigir placa permanente")
	# Carga e disparo não devem causar a antiga pausa na movimentação do robô.
	otto.recarga.stop()
	var antes: Vector2=otto.position
	Input.action_press("robo_direita")
	acao("robo_atacar",true)
	await pausa()
	acao("robo_atacar",false)
	await create_timer(0.12).timeout
	Input.action_release("robo_direita")
	conferir(otto.position.x>antes.x+5,"Otto continua andando durante o disparo")
	await create_timer(0.4).timeout
	conferir(await andar(lucas,Vector2(976,368)),"Lucas alcança o pé da escada usando os corredores")
	conferir(await andar(lucas,Vector2(1040,240)),"Lucas sobe a rampa até a borda com Z correto")
	conferir(lucas.altura_nivel==1,"Subida real atualiza a altura")
	var passos_antes: int=int(passos.get(lucas.name,0))
	var pos: Vector2=lucas.position
	Input.action_press("guerreiro_direita")
	acao("lucas_pular",true)
	await pausa()
	acao("lucas_pular",false)
	Input.action_release("guerreiro_direita")
	await create_timer(0.5).timeout
	conferir(lucas.position.x>pos.x+55 and not lucas.pulando and lucas.altura_nivel==1,"Tecla F atravessa a fenda e pousa no mesmo nível")
	conferir(int(passos.get(lucas.name,0))==passos_antes,"Lucas não produz passos enquanto está no ar")
	conferir(await andar(lucas,f.saida.position+Vector2(0,24)),"Terraço após o salto leva à porta por movimento real")
	# Um objeto na altura errada não pode capturar a interação de outro objeto válido.
	var bau: Node2D=f.get_node("Objetos/BauJardim")
	conferir(await andar(otto,bau.position+Vector2(0,32)),"Baú opcional é acessível por movimento real")
	otto.vida_atual=50
	var vida: int=lucas.vida_atual
	acao("otto_interagir",true)
	await pausa()
	acao("otto_interagir",false)
	conferir(bau.ativo and otto.vida_atual==80 and lucas.vida_atual==mini(lucas.vida_maxima,vida+30),"I abre baú, muda estado e recupera a equipe")
	conferir(not bau.interagir(otto) and otto.vida_atual==80,"Baú aberto não duplica a recompensa")
	otto.altura_nivel=1
	conferir(f.alvo_interacao(otto)==null,"Interação ignora objetos de outro nível")
	otto.altura_nivel=0
	# Guardas permanecem no chão real; vencê-los exige projéteis reais, sem receber_dano direto.
	for indice in range(2):
		var inimigo: CharacterBody2D=f.atores[2+indice]
		var ponto: Vector2=inimigo.position+Vector2(-48,0)
		conferir(await andar(otto,ponto),"Otto alcança a área do guarda "+str(indice))
		for tentativa in range(12):
			if inimigo.esta_morto: break
			otto.mira.travada=true
			otto.mira.direcao=(inimigo.position+Vector2(0,-10)-(otto.position+Vector2(0,-15))).normalized()
			acao("robo_atacar",true)
			await pausa()
			acao("robo_atacar",false)
			await create_timer(0.45).timeout
		conferir(inimigo.esta_morto,"Projéteis reais derrotam guarda "+str(indice))
	conferir(await andar(otto,Vector2(1040,240)),"Otto alcança a mesma escada e a borda pelo chão real")
	var passos_otto: int=int(passos.get(otto.name,0))
	var antes_salto: Vector2=otto.position
	Input.action_press("robo_direita")
	acao("otto_pular",true)
	await pausa()
	acao("otto_pular",false)
	Input.action_release("robo_direita")
	await create_timer(0.5).timeout
	conferir(otto.position.x>antes_salto.x+55 and otto.altura_nivel==1 and not otto.pulando,"P atravessa a fenda com Otto")
	conferir(int(passos.get(otto.name,0))==passos_otto,"Otto não produz passos enquanto está no ar")
	conferir(await andar(otto,f.saida.position+Vector2(0,24)),"Otto alcança o portal após o salto")
	f._physics_process(0.016)
	conferir(f.concluida,"Percurso cooperativo completo conclui a fase com ambos no portal")
	await create_timer(0.8).timeout
	if is_instance_valid(current_scene): current_scene.queue_free()
	await process_frame
	root.get_node("InterfaceAudio").parar()
	await create_timer(0.15).timeout
	if falhas.is_empty(): print("JARDIM_OK: ",checks," verificacoes com comandos, travessia, tiro, escada, salto e bau."); quit(0)
	else: print("JARDIM_FALHAS: ",falhas); quit(1)
