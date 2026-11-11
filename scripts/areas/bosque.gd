extends BaseArea

const SOM_PLACA = preload("res://assets/SONS/INTERFACE/CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg")
const SOM_ALVO = preload("res://assets/SONS/INTERFACE/SELECAO/KENNEY_INTERFACE_SOUNDS/select_001.ogg")
const SOM_PONTE = preload("res://assets/SONS/CENARIO/PONTE/ponte_mecanismo.wav")
const MUSICA = preload("res://assets/Ninja Adventure - Asset Pack/Audio/Musics/35 - Adventure.ogg")
const CHEGADA = Rect2(640,220,70,62)

var ponte_pronta := false
var concluido := false
var placa_ativa := false
var abrindo := false
var revelou := false
var sem_progresso := 0.0
var dica_extra := false
var mensagem_restante := 0.0
var som: AudioStreamPlayer
var musica: AudioStreamPlayer

func _ready() -> void:
	super._ready()
	$Placa/SignalEmitter.channel = &"bosque_placa"
	$Placa/hitbox.collision_mask = 0
	$Cristal.aceso.connect(_abrir)
	$Otto.disparou.connect(_acompanhar_tiro)
	for heroi in [$Lucas,$Otto]:
		heroi.get_node("Visual/AnimatedSprite2D").scale = Vector2.ONE
		heroi.get_node("BarraVida").hide()
		var passos := Node2D.new()
		passos.set_script(load("res://scripts/areas/passos_bosque.gd"))
		heroi.add_child(passos)
	$Lucas.nome_label.text = "Lucas"
	$Otto.nome_label.text = "Otto"
	$Camera.position = Vector2(280,256)
	$Camera.zoom = Vector2(1.3,1.3)
	som = AudioStreamPlayer.new()
	add_child(som)
	som.volume_db = -15
	musica = AudioStreamPlayer.new()
	musica.stream = MUSICA
	musica.set("parameters/looping",1)
	musica.volume_db = -23
	add_child(musica)
	musica.play()
	var ambiente := Node2D.new()
	ambiente.z_index = 1
	ambiente.set_script(load("res://scripts/areas/ambiente_bosque.gd"))
	add_child(ambiente)
	$Dicas/Texto.add_theme_font_size_override("font_size",11)
	_mensagem("Vamos explorar! Lucas: W A S D. Otto: setas.",4)
	call_deferred("_conversa_inicio")

func _conversa_inicio() -> void:
	await Convivencia.falar("bosque_inicio",[
		[0,"Oi! Sou Lucas. Dizem que este bosque esconde ruínas cheias de segredos!"],
		[1,"Sou Otto! Será que tem uma porta secreta? Bip! Fiquei curioso!"],
		[0,"Eu também! Quer explorar comigo? Dois amigos podem ter ótimas ideias!"],
		[1,"Quero! Minhas perninhas seguem as setas do teclado."],
		[0,"E eu ando com W, A, S e D. Vamos devagar para descobrir as pistas!"]
	])

func _som(stream: AudioStream) -> void:
	if musica.stream_paused:
		return
	som.stream = stream
	som.play()

func _exit_tree() -> void:
	if musica:
		musica.stop()
	if som:
		som.stop()

func _mensagem(texto: String, duracao: float = 6.0) -> void:
	$Dicas/Texto.text = texto
	mensagem_restante = minf(duracao,4.0)
	$Dicas/Texto.modulate.a = 1.0
	sem_progresso = 0.0
	dica_extra = false

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event.is_action_pressed("alternar_audio"):
		musica.stream_paused = not musica.stream_paused
		som.stream_paused = musica.stream_paused

func _physics_process(delta: float) -> void:
	mensagem_restante = maxf(0.0,mensagem_restante-delta)
	$Dicas/Texto.modulate.a = clampf(mensagem_restante / 0.5,0.0,1.0)
	if mensagem_restante == 0:
		$Dicas/Texto.text = ""
	if not revelou and maxf($Lucas.position.x,$Otto.position.x) > 205:
		revelou = true
		var camera := create_tween().set_parallel(true)
		camera.tween_property($Camera,"position",Vector2(384,256),1.1)
		var janela := get_viewport_rect().size
		var escala := maxf(janela.x / 768.0, janela.y / 480.0)
		camera.tween_property($Camera,"zoom",Vector2.ONE * escala,1.1)
		_mensagem("Lucas, tente pisar na pedra!")
		Convivencia.falar("bosque_rio",[
			[0,"Opa! O rio cortou nosso caminho. E a ponte está guardada!"],
			[1,"Veja a pedra e aquela torre! Será que são peças de uma charada?"],
			[0,"Vou pisar na pedra. Você observa a torre, combinado?"]
		])
	var pisou: bool = $Lucas.position.distance_to($Placa.position) < 14 and not $Lucas.pulando
	if pisou != placa_ativa:
		placa_ativa = pisou
		$Placa.bodies_on_button = 1 if pisou else 0
		if pisou:
			$Placa._press()
		else:
			$Placa._release()
		if not abrindo and not ponte_pronta:
			$Cristal.livre = pisou
			$Cristal.atualizar_visual()
			_som(SOM_PLACA)
			_mensagem("O alvo apareceu! Otto, mire com o mouse e clique." if pisou else "O alvo guardou. Lucas, volte para a pedra.")
			if pisou:
				Convivencia.falar("bosque_placa",[
					[1,"Bip-bip! Achei o alvo! Fique na pedra enquanto eu miro."],
					[0,"Pode contar comigo! Se errar, tente de novo. Eu espero!"],
					[1,"Obrigado! Vou mirar com o mouse e clicar. Lá vai minha esfera!"]
				])
	if revelou and not abrindo and not ponte_pronta:
		sem_progresso += delta
		if sem_progresso > 16 and not dica_extra:
			dica_extra = true
			$Dicas/Texto.text = "Lucas fica na pedra. Otto pode tentar quantas vezes quiser."
			mensagem_restante = 4.0
			mensagem_restante = 7
	if ponte_pronta and not concluido and CHEGADA.has_point($Lucas.position) and CHEGADA.has_point($Otto.position):
		concluido = true
		_entrar_na_masmorra()

func _entrar_na_masmorra() -> void:
	Convivencia.ganhar("bosque_entrada")
	await Convivencia.falar("bosque_entrada",[
		[1,"Uau, que portão grandão! Meu motor fez até um friozinho na barriga."],
		[0,"O meu também! Podemos ir devagar e cuidar um do outro."],
		[1,"Com um amigo fica mais fácil. Próxima parada: os segredos das ruínas!"]
	])
	_mensagem("Encontramos a entrada! Vamos juntos!",3)
	_som(SOM_PONTE)
	$Entrada/Porta.play("abrir")
	for heroi in [$Lucas,$Otto]:
		heroi.controlado = false
		heroi.velocity = Vector2.ZERO
		heroi.set_physics_process(false)
		heroi.olhar_para(Vector2.UP)
		heroi.animacao.play("walk_up")
	await $Entrada/Porta.animation_finished
	var entrar := create_tween().set_parallel(true)
	entrar.tween_property($Lucas,"position",Vector2(666,199),0.9)
	entrar.tween_property($Otto,"position",Vector2(682,199),0.9)
	entrar.tween_property($Lucas,"modulate:a",0.0,0.35).set_delay(0.65)
	entrar.tween_property($Otto,"modulate:a",0.0,0.35).set_delay(0.65)
	await entrar.finished
	get_node("/root/FluxoTela").trocar("res://cenas/areas/area_3.tscn")

func _acompanhar_tiro(tiro: Node) -> void:
	if not ponte_pronta and not abrindo:
		tiro.tree_exiting.connect(_tiro_terminou)

func _tiro_terminou() -> void:
	if not abrindo and not ponte_pronta and is_inside_tree():
		som.pitch_scale = 0.8
		_som(SOM_PLACA)
		som.pitch_scale = 1.0

func _abrir() -> void:
	if ponte_pronta or abrindo:
		return
	abrindo = true
	_som(SOM_ALVO)
	_mensagem("Acertou! A ponte está abrindo.",4)
	await get_tree().create_timer(0.25,false).timeout
	_som(SOM_PONTE)
	var anim := create_tween()
	for parte in $Ponte.get_children():
		parte.modulate.a = 1.0
		parte.scale.x = 0.03
		var pos_final: float = parte.position.y
		parte.position.y -= 6
		anim.tween_property(parte,"scale:x",1.0,0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		anim.parallel().tween_property(parte,"position:y",pos_final,0.20)
	anim.tween_callback(func():
		ponte_pronta = true
		abrindo = false
		$Bloqueio/CollisionShape2D.set_deferred("disabled",true)
		_mensagem("A ponte está pronta. Vamos juntos!",5)
		Convivencia.ganhar("bosque_ponte")
		Convivencia.falar("bosque_ponte",[
			[0,"Olha a ponte se abrindo! Nossas ideias funcionaram juntas!"],
			[1,"Você segurou a pedra e eu acertei o alvo. Somos uma dupla e tanto!"],
			[0,"Toca aqui, Otto! Agora vamos descobrir o que tem naquele portão!"]
		])
	)
