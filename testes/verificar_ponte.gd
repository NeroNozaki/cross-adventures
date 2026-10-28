extends SceneTree
var erros: Array[String]=[]
var checks: int=0
func _initialize() -> void: call_deferred("rodar")
func conferir(ok: bool,t: String) -> void:
	checks+=1
	if not ok: erros.append(t); push_error(t)
func rodar() -> void:
	AudioServer.set_bus_mute(0,true)
	var f: Node2D=load("res://cenas/fases/01_jardim.tscn").instantiate()
	root.add_child(f); current_scene=f
	await physics_frame
	await physics_frame
	f.set_physics_process(false)
	for ator in f.atores: ator.set_physics_process(false)
	var ponte: Node2D=f.get_node("PonteAnimada")
	ponte.set_process(false)
	var ponto: Vector2=Vector2(432,656)
	conferir(f.altura_em(ponto)==-1 and not ponte.pronta,"Canal começa sem passagem")
	conferir(ponte.audio.bus=="SFX" and ponte.audio.stream.get_length()>2,"Ponte tem som próprio no bus silenciável")
	f.sinais.ponte=true
	ponte.avancar(0.5)
	conferir(ponte.tempo>0 and not ponte.pronta and f.altura_em(ponto)==-1,"Construção animada não cria chão antes do encaixe")
	conferir(not f.get_node("CanaisDeAgua").ponte_em(Vector2i(13,20)),"Água permanece sob as partes em elevação")
	f.lucas.position=Vector2(368,656)
	conferir(not f.tentar_salto(f.lucas,Vector2.RIGHT),"Não se pode pousar na ponte incompleta")
	ponte.avancar(1.4)
	conferir(ponte.pronta and f.altura_em(ponto)==0,"Último encaixe libera a travessia")
	conferir(f.get_node("CanaisDeAgua").ponte_em(Vector2i(13,20)),"Água deixa de cobrir a ponte pronta")
	f.sinais.placa_a=false
	for i in range(10): ponte.avancar(0.5)
	conferir(ponte.pronta and ponte.disparos_som==1,"Ponte fica aberta e som não se repete")
	f.sinais.clear(); ponte.avancar(0)
	conferir(not ponte.pronta and f.altura_em(ponto)==-1,"Reinício remove a passagem e reinicializa animação")
	var placa: Node2D=f.get_node("Objetos/PlacaA")
	var cristal: Node2D=f.get_node("Objetos/Cristal")
	conferir(placa.position.distance_to(cristal.position)>=160,"Mecanismos têm espaço entre si")
	var q: PhysicsRayQueryParameters2D=PhysicsRayQueryParameters2D.create(placa.position,cristal.position,1)
	q.exclude=[cristal.get_rid()]
	conferir(not f.get_world_2d().direct_space_state.intersect_ray(q).is_empty(),"Salas distintas impedem um tiro direto da posição da placa")
	f.lucas.position=placa.position
	f._physics_process(0.016)
	var tiro: Node2D=load("res://cenas/combate/projetil.tscn").instantiate()
	cristal.receber_projetil(tiro)
	conferir(not f.sinais.get("cristal",false),"Tiro direto é recusado mesmo com Lucas na placa")
	f.lucas.position+=Vector2(0,64)
	f._physics_process(0.016)
	tiro.ricochetes=1
	cristal.receber_projetil(tiro)
	conferir(not f.sinais.get("cristal",false),"Tiro refletido ainda exige o parceiro na placa")
	f.lucas.position=placa.position
	f._physics_process(0.016)
	cristal.receber_projetil(tiro)
	conferir(f.sinais.get("cristal",false),"Reflexão com cooperação destrava o cristal")
	tiro.free()
	# Corredor de teste curto: previsão e tiro devem alcançar cinco contatos reais.
	for x in [100,200]:
		var parede: StaticBody2D=StaticBody2D.new()
		parede.position=Vector2(x,688)
		parede.collision_layer=1
		var col: CollisionShape2D=CollisionShape2D.new()
		var forma: RectangleShape2D=RectangleShape2D.new()
		forma.size=Vector2(4,80); col.shape=forma
		parede.add_child(col); f.add_child(parede)
	f.otto.position=Vector2(144,688)
	f.otto.mira.travada=true
	f.otto.mira.direcao=Vector2.RIGHT
	await physics_frame
	await physics_frame
	f.otto.mira.atualizar(Vector2(1000,688),1)
	conferir(f.otto.mira.trajeto.size()==6,"Previsão desenha os cinco contatos possíveis")
	f.otto.recarga.stop()
	var bala: Node2D=f.otto.disparar(true)
	conferir(bala!=null and bala.max_ricochetes==5,"Esfera carregada recebe a regra de cinco ricochetes")
	if bala!=null:
		var contatos: Array[int]=[]
		var sobreviveu_quarto: Array[bool]=[false]
		bala.velocidade=1800
		bala.ricocheteou.connect(func(n: int):
			contatos.append(n)
			if n==4: sobreviveu_quarto[0]=not bala.encerrado
		)
		await create_timer(1.0).timeout
		conferir(contatos==[1,2,3,4,5] and not is_instance_valid(bala),"Tiro apaga exatamente no quinto contato")
		conferir(sobreviveu_quarto[0],"Quarto contato não encerra o tiro")
	# Em espaço aberto, a previsão não ultrapassa a duração real de cada tipo de tiro.
	f.otto.position=Vector2(4000,4000)
	for carregado in [false,true]:
		f.otto.recarga.stop()
		var longo: Node2D=f.otto.disparar(carregado)
		f.otto.mira.atualizar(Vector2(5000,4000),1.0 if carregado else 0.0)
		var linha: PackedVector2Array=f.otto.mira.trajeto
		conferir(linha.size()==2 and absf(linha[0].distance_to(linha[1])-longo.velocidade*longo.tempo_de_vida)<1,"Previsão respeita o alcance real do tiro "+str(carregado))
		longo.queue_free()
	f.queue_free()
	await process_frame
	root.get_node("InterfaceAudio").parar()
	await create_timer(0.1).timeout
	if erros.is_empty(): print("PONTE_OK: ",checks," verificacoes de puzzle, construcao, som e cinco ricochetes."); quit(0)
	else: print("PONTE_FALHAS: ",erros); quit(1)
