extends SceneTree
var erros: Array[String]=[]
var checks: int=0
func _initialize() -> void: call_deferred("rodar")
func conferir(ok: bool,texto: String) -> void:
	checks+=1
	if not ok: erros.append(texto); push_error(texto)
func rodar() -> void:
	AudioServer.set_bus_mute(0,true)
	var f: Node2D=load("res://cenas/fases/01_jardim.tscn").instantiate()
	root.add_child(f); current_scene=f
	await physics_frame
	await physics_frame
	f.set_physics_process(false)
	for ator in f.atores: ator.set_physics_process(false)
	var vida: Node2D=f.get_node("CanaisDeAgua/VidaNaAgua")
	vida.set_process(false)
	vida.rng.seed=42
	conferir(vida.peixes.size()==6,"Cardume tem quantidade limitada")
	var iniciais: Array[Vector2]=[]
	for peixe in vida.peixes: iniciais.append(peixe.p)
	var seguro: bool=true
	var limitado: bool=true
	var gotas: bool=false
	var ondas: bool=false
	for i in range(600):
		vida.avancar(0.1)
		gotas=gotas or not vida.gotas.is_empty()
		ondas=ondas or vida.ondas.size()>1
		limitado=limitado and vida.ondas.size()<=vida.MAX_ONDAS and vida.gotas.size()<=vida.MAX_GOTAS
		for peixe in vida.peixes: seguro=seguro and vida.molhado(peixe.p)
	var moveu: bool=false
	for i in range(vida.peixes.size()): moveu=moveu or iniciais[i].distance_to(vida.peixes[i].p)>12
	conferir(moveu,"Peixes nadam e mudam de posição")
	conferir(seguro,"Peixes permanecem dentro da água ao nadar")
	conferir(gotas and ondas,"Gotas e ondas surgem durante simulação prolongada")
	conferir(limitado,"Efeitos expiram e mantêm limites de memória")
	f.sinais.ponte=true
	f.get_node("PonteAnimada").avancar(2.0)
	for i in range(150): vida.avancar(0.1)
	seguro=true
	for peixe in vida.peixes: seguro=seguro and vida.molhado(peixe.p)
	conferir(seguro,"Abrir a ponte não deixa peixes na travessia")
	conferir(vida.get_child_count()==0,"Ambientação não cria nós/colisões por partícula")
	for ator in [f.lucas,f.otto]:
		var respirar: Node=ator.get_node("Respiracao")
		respirar.set_process(false)
		var pos: Vector2=ator.position
		var corpo: Shape2D=ator.get_node("CollisionShape2D").shape
		respirar.tempo=0; respirar._process(0.8)
		var inspirou: float=respirar.intensidade
		respirar._process(1.6)
		conferir(inspirou>0.9 and respirar.intensidade<0.1,"Respiração tem inspiração e expiração: "+str(ator.name))
		conferir(ator.position==pos and ator.get_node("CollisionShape2D").shape==corpo,"Respiração preserva posição e colisão")
		ator.atacando=true; respirar._process(0.1)
		conferir(respirar.intensidade==0,"Respiração não modifica o ataque")
		ator.atacando=false; ator.pulando=true; respirar._process(0.1)
		conferir(respirar.intensidade==0,"Respiração não modifica o salto")
		ator.pulando=false
	var placa: Node2D=f.get_node("Objetos/PlacaA")
	placa.set_process(false)
	placa.definir_ativo(true); placa._process(0.2)
	conferir(placa.pressao_visual>0.9 and placa.collision_layer==0,"Botão desce sem bloquear o jogador")
	placa.definir_ativo(false); placa._process(0.2)
	conferir(placa.pressao_visual==0,"Botão retorna ao aliviar o peso")
	var bau: Node2D=f.get_node("Objetos/BauJardim")
	conferir(bau.quadros_bau.size()==5,"Baú usa cinco quadros próprios, sem incluir os sprites da alavanca")
	var recortes: bool=true
	for r: Rect2 in bau.quadros_bau: recortes=recortes and r.has_area() and Rect2(Vector2.ZERO,bau.BAUS.get_size()).encloses(r)
	conferir(recortes,"Quadros do baú são inteiros e dentro do atlas")
	# IA real, sem alvo próximo: caminhar lentamente, pausar e conservar o chão.
	f.sinais.ponte=false
	var mob: CharacterBody2D=f.atores[2]
	mob.rng_patrulha.seed=10
	mob.espera_patrulha=0
	mob.set_physics_process(true)
	var origem: Vector2=mob.position
	var houve_pausa: bool=false
	var houve_andar: bool=false
	var no_chao: bool=true
	var lento: bool=true
	for i in range(500):
		await physics_frame
		houve_pausa=houve_pausa or mob.estado_ia=="repouso"
		houve_andar=houve_andar or mob.position.distance_to(origem)>8
		no_chao=no_chao and f.altura_em(mob.position)==mob.altura_nivel and mob.position.distance_to(origem)<mob.raio_patrulha+12
		lento=lento and mob.velocity.length()<=mob.velocidade*0.33
	conferir(houve_andar and houve_pausa,"Inimigo patrulha e faz pausas espontâneas")
	conferir(no_chao,"Patrulha permanece no chão e perto de sua sala")
	conferir(lento,"Patrulha usa velocidade inferior ao combate")
	f.otto.position=mob.position+Vector2(0,48)
	await physics_frame
	await physics_frame
	conferir(mob.estado_ia in ["perseguir","atacar"],"Detectar herói interrompe a patrulha")
	mob.receber_dano(999,Vector2.ZERO)
	await physics_frame
	var queda: Vector2=mob.position
	await create_timer(0.25).timeout
	conferir(mob.position==queda and mob.esta_morto,"Morte encerra a movimentação de patrulha")
	f.queue_free()
	await process_frame
	root.get_node("InterfaceAudio").parar()
	await create_timer(0.1).timeout
	if erros.is_empty(): print("AMBIENTE_OK: ",checks," verificacoes de agua, respiracao, itens e patrulha."); quit(0)
	else: print("AMBIENTE_FALHAS: ",erros); quit(1)
