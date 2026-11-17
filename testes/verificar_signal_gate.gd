extends SceneTree

class EntradaFalsa:
	extends Node

	var travamentos: int = 0

	func travar_estado_atual() -> void:
		travamentos += 1


var falhas: Array[String] = []
var total := 0


func _initialize() -> void:
	call_deferred("rodar")


func conferir(ok: bool, texto: String) -> void:
	total += 1
	if not ok:
		falhas.append(texto)
		push_error(texto)


func quadros() -> void:
	await physics_frame
	await process_frame
	await physics_frame


func barramento() -> Node:
	return root.get_node("SignalBus")


func criar_entrada(canal: StringName, inverter := false, valor_inicial := false) -> SignalGateInput:
	return SignalGateInput.new(canal, inverter, valor_inicial)


func criar_gate(entradas: Array[SignalGateInput], saida: StringName, single_use := false) -> SignalGate:
	var gate: SignalGate = load("res://cenas/signal_components/signal_gate.tscn").instantiate()
	gate.entradas = entradas
	gate.canal_saida = saida
	gate.single_use = single_use
	root.add_child(gate)
	return gate


func observar(canal: StringName) -> Dictionary:
	var valores: Array = []
	var callback := func(valor): valores.append(valor)
	barramento().subscribe(canal, callback)
	return {"valores": valores, "callback": callback}


func parar_observacao(canal: StringName, observacao: Dictionary) -> void:
	barramento().unsubscribe(canal, observacao["callback"])


func rodar() -> void:
	AudioServer.set_bus_mute(0, true)

	var f1 := EntradaFalsa.new()
	f1.name = "F1"
	var f2 := EntradaFalsa.new()
	f2.name = "F2"
	var f3 := EntradaFalsa.new()
	f3.name = "F3"
	root.add_child(f1)
	root.add_child(f2)
	root.add_child(f3)

	var e1 := criar_entrada(&"teste.gate.a")
	e1.no_emissor = NodePath("../F1")
	var e2 := criar_entrada(&"teste.gate.b")
	e2.no_emissor = NodePath("../F2")
	var e3 := criar_entrada(&"teste.gate.c")
	e3.no_emissor = NodePath("../F3")

	var observacao := observar(&"teste.gate.saida")
	var gate := criar_gate([e1, e2, e3], &"teste.gate.saida", true)
	await quadros()

	conferir(not gate.esta_ativado(), "gate com tres entradas comeca desativado")
	barramento().publish(&"teste.gate.a", true)
	await quadros()
	conferir(not gate.esta_ativado(), "gate nao ativa com apenas uma entrada verdadeira")
	barramento().publish(&"teste.gate.b", true)
	await quadros()
	conferir(not gate.esta_ativado(), "gate nao ativa com duas de tres entradas verdadeiras")
	barramento().publish(&"teste.gate.c", true)
	await quadros()
	conferir(gate.esta_ativado(), "gate ativa quando todas as condicoes sao atendidas")
	conferir(observacao["valores"] == [true], "gate publica true uma unica vez")
	conferir(f1.travamentos == 1 and f2.travamentos == 1 and f3.travamentos == 1, "single_use trava todas as entradas")
	barramento().publish(&"teste.gate.a", false)
	barramento().publish(&"teste.gate.b", false)
	await quadros()
	conferir(gate.esta_ativado(), "single_use mantem a saida ativa")
	conferir(observacao["valores"] == [true], "single_use nao publica false depois de ativar")
	parar_observacao(&"teste.gate.saida", observacao)
	gate.queue_free()
	await quadros()

	var f4 := EntradaFalsa.new()
	f4.name = "F4"
	var f5 := EntradaFalsa.new()
	f5.name = "F5"
	root.add_child(f4)
	root.add_child(f5)
	var e4 := criar_entrada(&"teste.gate.live.a")
	e4.no_emissor = NodePath("../F4")
	var e5 := criar_entrada(&"teste.gate.live.b")
	e5.no_emissor = NodePath("../F5")

	var observacao_live := observar(&"teste.gate.live.saida")
	var gate_live := criar_gate([e4, e5], &"teste.gate.live.saida")
	await quadros()

	barramento().publish(&"teste.gate.live.a", true)
	barramento().publish(&"teste.gate.live.b", true)
	await quadros()
	conferir(gate_live.esta_ativado(), "gate sem single_use ativa com todas as entradas")
	conferir(observacao_live["valores"] == [true], "gate live publica a ativacao")
	conferir(f4.travamentos == 0 and f5.travamentos == 0, "gate live nao trava as entradas")
	barramento().publish(&"teste.gate.live.a", true)
	await quadros()
	conferir(observacao_live["valores"] == [true], "gate live nao repete publicacoes iguais")
	barramento().publish(&"teste.gate.live.b", false)
	await quadros()
	conferir(not gate_live.esta_ativado(), "gate live desativa quando uma condicao deixa de valer")
	conferir(observacao_live["valores"] == [true, false], "gate live publica true e depois false")
	parar_observacao(&"teste.gate.live.saida", observacao_live)
	gate_live.queue_free()
	f4.queue_free()
	f5.queue_free()
	await quadros()

	var f6 := EntradaFalsa.new()
	f6.name = "F6"
	var f7 := EntradaFalsa.new()
	f7.name = "F7"
	root.add_child(f6)
	root.add_child(f7)
	var e6 := criar_entrada(&"teste.gate.off", true)
	e6.no_emissor = NodePath("../F6")
	var e7 := criar_entrada(&"teste.gate.on")
	e7.no_emissor = NodePath("../F7")
	var gate_off := criar_gate([e6, e7], &"teste.gate.off.saida", true)
	await quadros()
	conferir(not gate_off.esta_ativado(), "entrada invertida usa false inicial sem ativar sozinha")
	barramento().publish(&"teste.gate.on", true)
	await quadros()
	conferir(gate_off.esta_ativado(), "entrada invertida nao precisa emitir para valer como desligada")
	conferir(f6.travamentos == 1 and f7.travamentos == 1, "single_use trava entrada invertida sem evento")
	gate_off.queue_free()
	f6.queue_free()
	f7.queue_free()
	await quadros()

	var observacao_inicial := observar(&"teste.gate.inicial.saida")
	var e_inicial := criar_entrada(&"teste.gate.inicial", false, true)
	var gate_inicial := criar_gate([e_inicial], &"teste.gate.inicial.saida")
	await quadros()
	conferir(gate_inicial.esta_ativado(), "valor_inicial participa da avaliacao inicial")
	conferir(observacao_inicial["valores"] == [true], "gate publica o estado inicial verdadeiro")
	parar_observacao(&"teste.gate.inicial.saida", observacao_inicial)
	gate_inicial.queue_free()
	await quadros()

	var observacao_invertida := observar(&"teste.gate.invertida.saida")
	var e_invertida := criar_entrada(&"teste.gate.invertida", true, true)
	var gate_invertida := criar_gate([e_invertida], &"teste.gate.invertida.saida")
	await quadros()
	barramento().publish(&"teste.gate.invertida", Vector2.ONE)
	await quadros()
	conferir(gate_invertida.esta_ativado(), "payload nao suportado vira false antes da inversao")
	conferir(observacao_invertida["valores"] == [true], "entrada invertida publica ao receber payload falso")
	parar_observacao(&"teste.gate.invertida.saida", observacao_invertida)
	gate_invertida.queue_free()
	await quadros()

	var botao: Node2D = load("res://cenas/objects/interactables/button.tscn").instantiate()
	botao.name = "BotaoGate"
	botao.channel = &"teste.gate.botao"
	root.add_child(botao)
	var e_botao := criar_entrada(&"teste.gate.botao")
	e_botao.no_emissor = NodePath("../BotaoGate")
	var gate_botao := criar_gate([e_botao], &"teste.gate.botao.saida", true)
	await quadros()
	botao._on_body_entered(null)
	await quadros()
	conferir(gate_botao.esta_ativado() and botao.pressed, "botao real ativa o gate e fica pressionado")
	conferir(botao.travado and botao.single_use, "botao real fica travado pelo gate single_use")
	botao._on_body_exited(null)
	await quadros()
	conferir(botao.pressed, "botao travado nao solta ao sair")
	gate_botao.queue_free()
	botao.queue_free()
	await quadros()

	var switch: Node2D = load("res://cenas/objects/interactables/switch.tscn").instantiate()
	switch.name = "SwitchGate"
	switch.channel = &"teste.gate.switch"
	root.add_child(switch)
	var e_switch := criar_entrada(&"teste.gate.switch")
	e_switch.no_emissor = NodePath("../SwitchGate")
	var gate_switch := criar_gate([e_switch], &"teste.gate.switch.saida", true)
	await quadros()
	switch.receber_dano(1, Vector2.ZERO)
	await quadros()
	conferir(gate_switch.esta_ativado() and switch.get_state() == &"gold", "switch real ativa o gate e fica dourado")
	conferir(switch.travado and switch.is_spent(), "switch real fica travado pelo gate single_use")
	switch.receber_dano(1, Vector2.ZERO)
	await quadros()
	conferir(switch.get_state() == &"gold", "switch travado ignora novo dano")
	gate_switch.queue_free()
	switch.queue_free()
	await quadros()

	f1.queue_free()
	f2.queue_free()
	f3.queue_free()
	await quadros()

	if falhas.is_empty():
		print("SIGNAL_GATE_OK: %d verificacoes do gate de sinais." % total)
		quit(0)
	else:
		print(falhas)
		quit(1)
