extends Control

const ARTE_BOTAO = preload("res://assets/INTERFACE/botao_reliquia.svg")

@export_file("*.tscn") var proxima_cena: String = "res://cenas/areas/bosque.tscn"
var tempo_jornada := 0.0
@onready var convite: Label = $BoasVindas/Texto/Convite

func _ready():
	_estilizar_botoes()
	create_tween().tween_property($Musica, "volume_db", -16.0, 1.2)
	$VBoxContainer/PLAY.grab_focus()
	var botoes := $VBoxContainer.get_children()
	botoes.append($BoasVindas/Comecar)
	for botao: Button in botoes:
		botao.mouse_entered.connect(_som.bind($Sobre))
		botao.focus_entered.connect(_som.bind($Sobre))
		botao.button_down.connect(_som.bind($Clique))

func _estilizar_botoes() -> void:
	var botoes := $VBoxContainer.get_children()
	botoes.append($BoasVindas/Comecar)
	$BoasVindas/Comecar.offset_left = -100
	$BoasVindas/Comecar.offset_right = 100
	for botao: Button in botoes:
		for estado in ["normal", "hover", "focus", "pressed"]:
			var placa := StyleBoxTexture.new()
			placa.texture = ARTE_BOTAO
			placa.texture_margin_left = 15
			placa.texture_margin_right = 15
			placa.texture_margin_top = 5
			placa.texture_margin_bottom = 5
			placa.content_margin_left = 18
			placa.content_margin_right = 18
			placa.content_margin_top = 5
			placa.content_margin_bottom = 5
			placa.modulate_color = Color("#fff0c5") if estado in ["hover", "focus"] else Color.WHITE
			botao.add_theme_stylebox_override(estado, placa)

func _som(player: AudioStreamPlayer) -> void:
	if not $Musica.stream_paused:
		player.play()

func _process(delta: float) -> void:
	if $Jornada.visible:
		tempo_jornada += delta
		var progresso := pingpong(tempo_jornada / 10.0, 1.0)
		$Jornada/Lucas.position = size * Vector2(lerpf(0.15, 0.9, progresso), 0.637)
		$Jornada/Otto.position = $Jornada/Lucas.position + Vector2(-42, 2)
		var sentido := "walk_right" if fmod(tempo_jornada, 20.0) < 10.0 else "walk_left"
		$Jornada/Lucas.play(sentido)
		$Jornada/Otto.play(sentido)
		var letras := mini(int(maxf(tempo_jornada - 0.85, 0.0) * 26), convite.text.length())
		if letras > convite.visible_characters:
			if letras / 4 > convite.visible_characters / 4:
				_som($Letra)
			convite.visible_characters = letras
	for item in $VBoxContainer.get_children():
		var button := item as Button
		button.pivot_offset = button.size * 0.5
		var target := 0.97 if button.button_pressed else (1.05 if button.has_focus() or button.is_hovered() else 1.0)
		button.scale = button.scale.lerp(Vector2.ONE * target, 1.0 - exp(-14.0 * delta))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("alternar_audio"):
		$Musica.stream_paused = not $Musica.stream_paused
		get_viewport().set_input_as_handled()
	
func _on_play_pressed() -> void:
	Convivencia.nova_partida()
	$VBoxContainer.hide()
	$Title.hide()
	$Jornada.modulate.a = 0
	$Jornada.show()
	$Jornada/Lucas.play("walk_right")
	$Jornada/Otto.play("walk_right")
	convite.visible_characters = 0
	$BoasVindas.modulate.a = 0
	$BoasVindas.show()
	var entrada := create_tween()
	entrada.tween_property($Jornada, "modulate:a", 1.0, 0.55)
	entrada.tween_property($BoasVindas, "modulate:a", 1.0, 0.35)
	$BoasVindas/Comecar.grab_focus()
	await entrada.finished
	$BoasVindas.show()
	$BoasVindas/Comecar.grab_focus()

func _abrir_ajuda() -> void:
	Convivencia.abrir_ajuda()


func _on_exit_pressed() -> void:
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func _iniciar_transicao() -> void:
	if proxima_cena.is_empty():
		return
	var fluxo: Node = get_node_or_null("/root/FluxoTela")
	if fluxo and fluxo.has_method("trocar"):
		create_tween().tween_property($Musica, "volume_db", -45.0, 0.24)
		fluxo.trocar(proxima_cena)
	else:
		push_error("FluxoTela nao encontrado para trocar a cena.")
	
	
