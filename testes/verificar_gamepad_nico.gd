extends SceneTree
var total := 0
var erros := 0

func _initialize() -> void:
	call_deferred("executar")

func conferir(ok: bool, texto: String) -> void:
	total += 1
	if not ok:
		erros += 1
		push_error(texto)

func eixo(indice: int, valor: float) -> void:
	var evento := InputEventJoypadMotion.new()
	evento.device = 0
	evento.axis = indice
	evento.axis_value = valor
	Input.parse_input_event(evento)

func botao(indice: int, pressionado: bool) -> void:
	var evento := InputEventJoypadButton.new()
	evento.device = 0
	evento.button_index = indice
	evento.pressed = pressionado
	Input.parse_input_event(evento)

func quadros(quantidade: int = 3) -> void:
	for i in quantidade:
		await physics_frame
	await process_frame

func executar() -> void:
	change_scene_to_file("res://cenas/areas/puzzle_02.tscn")
	await process_frame
	await quadros()
	var historia = root.get_node("HistoriaDupla")
	if historia.ativa:
		historia.finalizar()
	paused = false
	var nico = current_scene.nico
	var otto = current_scene.otto
	nico.position = Vector2(120,516)
	otto.position = Vector2(240,516)
	await quadros()
	var inicio_otto: Vector2 = otto.position
	var inicio: Vector2 = nico.position
	eixo(JOY_AXIS_LEFT_X,0.15)
	await quadros(10)
	conferir(nico.position.distance_to(inicio) < 0.1, "Zona morta evita movimento involuntário")
	eixo(JOY_AXIS_LEFT_X,0.6)
	await quadros(12)
	var parcial: float = nico.position.x - inicio.x
	conferir(parcial > 2, "Analógico move Nico para a direita")
	inicio = nico.position
	eixo(JOY_AXIS_LEFT_X,1)
	await quadros(12)
	var completo: float = nico.position.x - inicio.x
	conferir(completo > parcial * 1.5, "Velocidade responde à intensidade do analógico")
	eixo(JOY_AXIS_LEFT_X,0.9)
	eixo(JOY_AXIS_LEFT_Y,0.9)
	await quadros()
	conferir(Input.get_vector("player1_esquerda","player1_direita","player1_cima","player1_baixo").length() <= 1.001, "Diagonal não aumenta a velocidade máxima")
	conferir(otto.position.distance_to(inicio_otto) < 0.1, "Gamepad de Nico não move Otto")
	eixo(JOY_AXIS_LEFT_X,0)
	eixo(JOY_AXIS_LEFT_Y,0)
	await quadros()
	inicio = nico.position
	await quadros(8)
	conferir(nico.position.distance_to(inicio) < 0.1, "Soltar o analógico para imediatamente")
	botao(JOY_BUTTON_X,true)
	await quadros()
	conferir(nico.atacando and not nico.defendendo, "X azul executa o golpe")
	botao(JOY_BUTTON_X,false)
	await create_timer(0.8).timeout
	botao(JOY_BUTTON_B,true)
	await quadros()
	conferir(nico.defendendo, "B vermelho ergue o escudo")
	conferir(not paused and not current_scene.esta_pausado(), "B não abre a pausa durante a partida")
	botao(JOY_BUTTON_X,true)
	await quadros()
	conferir(not nico.atacando, "Escudo impede golpe simultâneo")
	botao(JOY_BUTTON_X,false)
	botao(JOY_BUTTON_B,false)
	await quadros()
	conferir(not nico.defendendo, "Soltar B abaixa o escudo")
	var tecla := InputEventKey.new()
	tecla.physical_keycode = KEY_F
	tecla.pressed = true
	Input.parse_input_event(tecla)
	await quadros()
	conferir(nico.atacando, "F continua funcionando como alternativa")
	tecla.pressed = false
	Input.parse_input_event(tecla)
	await create_timer(0.8).timeout
	botao(JOY_BUTTON_START,true)
	await process_frame
	conferir(paused and current_scene.esta_pausado(), "Start abre a pausa")
	botao(JOY_BUTTON_START,false)
	await process_frame
	botao(JOY_BUTTON_X,true)
	await create_timer(0.1).timeout
	conferir(not nico.atacando, "Nico não ataca ao usar o guia ou a pausa")
	botao(JOY_BUTTON_X,false)
	botao(JOY_BUTTON_START,true)
	await process_frame
	botao(JOY_BUTTON_START,false)
	await process_frame
	conferir(not paused, "Start retoma a partida")
	current_scene.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("GAMEPAD_NICO: %d verificações, %d falhas" % [total,erros])
	quit(0 if erros == 0 else 1)
