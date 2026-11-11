extends SceneTree

var falhas: Array[String] = []
var total := 0


func _initialize() -> void:
	call_deferred("rodar")


func conferir(ok: bool, texto: String) -> void:
	total += 1
	if not ok:
		falhas.append(texto)
		push_error(texto)


func evento_esc() -> InputEventKey:
	var evento := InputEventKey.new()
	evento.keycode = KEY_ESCAPE
	evento.physical_keycode = KEY_ESCAPE
	evento.pressed = true
	return evento


func conectado(botao: Button, metodo: String) -> bool:
	for conexao in botao.get_signal_connection_list("pressed"):
		var chamavel: Callable = conexao["callable"]
		if chamavel.get_method() == metodo:
			return true
	return false


func rodar() -> void:
	AudioServer.set_bus_mute(0, true)
	var script_area3: Script = load("res://scripts/areas/area3.gd")
	var area3: Node = script_area3.new()
	conferir(area3 is BaseArea, "area3 herda BaseArea")
	area3.free()

	var area := BaseArea.new()
	root.add_child(area)
	await process_frame
	await physics_frame
	var camada: CanvasLayer = area.get_node("CamadaPausa")
	var menu: PauseMenu = camada.get_child(0)
	conferir(camada.layer < 100, "pausa fica abaixo do FluxoTela")
	conferir(menu.process_mode == Node.PROCESS_MODE_ALWAYS, "menu funciona com a arvore pausada")
	conferir(not menu.visible and not paused, "menu comeca escondido e jogo livre")

	var esc := evento_esc()
	conferir(InputMap.event_is_action(esc, "ui_cancel"), "ESC esta mapeado para ui_cancel")
	Input.parse_input_event(esc)
	await process_frame
	await physics_frame
	conferir(paused, "ESC pausa o jogo")
	conferir(menu.visible, "ESC mostra o menu de pausa")
	var solta := evento_esc()
	solta.pressed = false
	Input.parse_input_event(solta)
	conferir(area.esta_pausado(), "BaseArea relata o estado pausado")

	var resume: Button = menu.get_node("VBoxContainer/resume")
	var controls: Button = menu.get_node("VBoxContainer/controls")
	var exit: Button = menu.get_node("VBoxContainer/exit")
	var menu_inicial: Button = menu.get_node("VBoxContainer/menu")
	conferir(menu.get_viewport().gui_get_focus_owner() == resume, "botao continuar recebe foco")
	conferir(conectado(resume, "_on_resume_pressed"), "continuar esta conectado")
	conferir(conectado(exit, "_on_exit_pressed"), "sair esta conectado")
	conferir(conectado(menu_inicial, "_on_menu_pressed"), "voltar ao inicio esta conectado")
	conferir(controls.get_signal_connection_list("pressed").is_empty(), "como jogar fica sem acao")

	resume.pressed.emit()
	conferir(not paused and not menu.visible, "continuar despausa e esconde o menu")

	Input.parse_input_event(evento_esc())
	await process_frame
	await physics_frame
	conferir(paused and menu.visible, "ESC abre novamente o menu")
	Input.parse_input_event(evento_esc())
	await process_frame
	await physics_frame
	Input.parse_input_event(solta)
	conferir(not paused and not menu.visible, "ESC despausa e esconde o menu")

	area._unhandled_input(esc)
	menu_inicial.pressed.emit()
	await create_timer(1.2, true).timeout
	conferir(current_scene != null and current_scene.scene_file_path == PauseMenu.CENA_INICIAL, "menu inicial carrega via FluxoTela")
	conferir(not paused, "jogo continua despausado apos a transicao")

	menu.free()
	area.free()
	await create_timer(0.3, true).timeout

	if falhas.is_empty():
		print("PAUSA_OK: %d verificacoes de pausa, botoes e transicao ao menu." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
