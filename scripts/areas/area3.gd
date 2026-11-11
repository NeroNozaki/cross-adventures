extends BaseArea

@onready var button2 = $objects/button2
@onready var button3 = $objects/button3
@onready var switch2 = $objects/switch2

@onready var player1 = $Personagens/Player1
@onready var player2 = $Personagens/Player2
var _fences_opened := false
var aviso: Label
var tempo_aviso := 0.0
var etapa := -1
var musica: AudioStreamPlayer

func _ready() -> void:
	super._ready()
	player1.nome_label.text = "Lucas"
	player2.nome_label.text = "Otto"
	var hud_dupla := CanvasLayer.new()
	hud_dupla.set_script(load("res://scripts/areas/hud_dupla.gd"))
	add_child(hud_dupla)
	for heroi in [player1,player2]:
		var passos := Node2D.new()
		passos.set_script(load("res://scripts/areas/passos_bosque.gd"))
		heroi.add_child(passos)
	var ambiente := Node2D.new()
	ambiente.set_script(load("res://scripts/areas/ambiente_masmorra.gd"))
	add_child(ambiente)
	var hud := CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	aviso = Label.new()
	aviso.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	aviso.offset_top = 58
	aviso.offset_right = -20
	aviso.offset_left = 20
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.add_theme_font_size_override("font_size",11)
	aviso.add_theme_color_override("font_shadow_color",Color.BLACK)
	aviso.add_theme_constant_override("shadow_offset_x",1)
	aviso.add_theme_constant_override("shadow_offset_y",1)
	hud.add_child(aviso)
	musica = AudioStreamPlayer.new()
	musica.stream = load("res://assets/Ninja Adventure - Asset Pack/Audio/Musics/21 - Dungeon.ogg")
	musica.set("parameters/looping",1)
	musica.volume_db = -25
	musica.stream_paused = Convivencia.silenciado
	add_child(musica)
	musica.play()
	call_deferred("_conversa_chegada")
	
	# Connect both buttons to the same check
	if button2 and button2.has_signal("state_changed"):
		button2.state_changed.connect(_check_both_buttons)
	if button3 and button3.has_signal("state_changed"):
		button3.state_changed.connect(_check_both_buttons)

func _check_both_buttons(_state = null) -> void:
	if _fences_opened:
		return
	if not button2 or not button3:
		return

	# Both must currently be considered pressed
	var both_pressed := _is_button_pressed(button2) and _is_button_pressed(button3)
	if not both_pressed:
		return

	# Extra safety: make sure there is actually something standing on each
	if _get_bodies_on(button2) == 0 or _get_bodies_on(button3) == 0:
		return

	# Success — lock everything
	_fences_opened = true
	$objects/fence_set3.definir_ativado(true)
	_avisar("Boa parceria! O portão das duas pedras abriu.")
	_lock_button(button2)
	_lock_button(button3)
	Convivencia.ganhar("masmorra_placas")
	Convivencia.falar("masmorra_placas",[
		[0,"Cada um em uma pedra. Deu certo!"],
		[1,"Gosto de resolver as coisas com você, Lucas."]
	])

func _conversa_chegada() -> void:
	await Convivencia.falar("masmorra_chegada",[
		[1,"Que lugar diferente! Vamos observar antes de agir?"],
		[0,"Boa ideia. Sua atenção ajuda muito, Otto."]
	])


func _is_button_pressed(btn: Node) -> bool:
	if "pressed" in btn:
		return btn.pressed == true
	return false


func _get_bodies_on(btn: Node) -> int:
	if "bodies_on_button" in btn:
		return int(btn.bodies_on_button)
	return 0


func _lock_button(btn: Node) -> void:
	btn.single_use = true
	btn.pressed = true

	# Keep the button permanently "occupied" so it doesn't release
	if btn.has_method("set_deferred"):
		btn.set_deferred("bodies_on_button", 999)
	else:
		btn.bodies_on_button = 999

	# Play the permanently-pressed animation if it exists
	var anim = btn.get("animation")
	if anim and anim.has_method("play"):
		anim.play("3-pressed")


func _avisar(mensagem: String) -> void:
	aviso.text = mensagem
	tempo_aviso = 4.0

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event.is_action_pressed("alternar_audio"):
		musica.stream_paused = Convivencia.silenciado

func _process(_delta: float) -> void:
	tempo_aviso = maxf(0,tempo_aviso-_delta)
	aviso.modulate.a = clampf(tempo_aviso/0.5,0,1)
	var altura := minf(player1.global_position.y,player2.global_position.y)
	var nova_etapa := 0 if altura > 290 else (1 if altura > 0 else (2 if altura > -260 else 3))
	if nova_etapa > etapa:
		etapa = nova_etapa
		_avisar([
			"Salão da Parceria · Explorem as pedras e os alvos da sala.",
			"Duas pedras, dois amigos: tentem ficar em uma cada um!",
			"Observem o chão e esperem um caminho seguro antes de avançar.",
			"As plataformas se movem. Atravessem com calma e esperem pelo amigo."
		][etapa])
	if has_node("MarcadorPlayer2") and player2:
		$MarcadorPlayer2.position = player2.position + Vector2(0, 8)
		$MarcadorPlayer2.visible = not player2.esta_morto
