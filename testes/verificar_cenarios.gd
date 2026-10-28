extends SceneTree
var falhas: Array[String]=[]
var total: int=0
func _initialize() -> void: call_deferred("rodar")
func conferir(ok: bool,t: String) -> void:
	total+=1
	if not ok:
		falhas.append(t)
		push_error(t)
func passos() -> void:
	await physics_frame
	await physics_frame
	await process_frame
func rodar() -> void:
	AudioServer.set_bus_mute(0,true)
	for nome in ["01_jardim","02_galeria","03_oficina","04_santuario"]:
		var f: Node2D=load("res://cenas/fases/"+nome+".tscn").instantiate()
		root.add_child(f)
		current_scene=f
		await passos()
		for a in f.atores: a.set_physics_process(false)
		f.set_physics_process(false)
		for heroi in [f.lucas,f.otto]:
			var forma: CircleShape2D=CircleShape2D.new()
			forma.radius=9
			var q: PhysicsShapeQueryParameters2D=PhysicsShapeQueryParameters2D.new()
			q.shape=forma
			q.transform=Transform2D(0,heroi.position)
			q.collision_mask=1
			conferir(f.altura_em(heroi.position)==0 and f.get_world_2d().direct_space_state.intersect_shape(q).is_empty(),nome+": entrada livre")
		for objeto in f.get_node("Objetos").get_children():
			conferir(f.altura_em(objeto.position)==objeto.altura_nivel,nome+": objeto apoiado "+str(objeto.name))
		if nome=="01_jardim":
			var inimigo: CharacterBody2D=f.atores[2]
			var direcao: Vector2=f.direcao_ia(inimigo,f.lucas.position)
			conferir(direcao==Vector2.ZERO,"Ponte fechada impede rota da IA entre as margens")
			f.sinais.ponte=true
			inimigo.remove_meta("rota_cenario")
			direcao=f.direcao_ia(inimigo,f.lucas.position)
			conferir(direcao.length()>0.9,"Ponte aberta permite rota real pelos corredores")
		var camera: Camera2D=f.get_node("CameraCompartilhada")
		var e: InputEventKey=InputEventKey.new()
		e.physical_keycode=KEY_V
		e.pressed=true
		Input.parse_input_event(e)
		await passos()
		conferir(camera.visao_geral,nome+": V abre visao geral")
		e=InputEventKey.new()
		e.physical_keycode=KEY_V
		e.pressed=false
		Input.parse_input_event(e)
		await create_timer(0.4).timeout
		var tela: Rect2=Rect2(0,50,640,304)
		for heroi in [f.lucas,f.otto]:
			conferir(tela.has_point(heroi.get_global_transform_with_canvas().origin),nome+": mapa enquadra os dois herois")
		f.queue_free()
		await process_frame
		await create_timer(0.15).timeout
	if falhas.is_empty():
		print("CENARIOS_OK: %d verificacoes de apoio, entradas sem colisao, rotas condicionais e camera cooperativa." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
