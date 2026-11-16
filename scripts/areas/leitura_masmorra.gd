extends Node2D
## Sinalização sobre a fase colaborativa existente; não altera sua geometria.
var tempo := 0.0
var abrigo: Checkpoint
var aviso: Label
var tempo_aviso := 0.0

func _ready() -> void:
	var sala := get_parent()
	abrigo = sala.get_node("Checkpoint")
	for heroi in [sala.player1,sala.player2]:
		var passos := Node.new()
		passos.set_script(load("res://scripts/areas/passos_puzzle.gd"))
		heroi.add_child(passos)
	var nome := Label.new()
	nome.text = "ABRIGO"
	nome.position = abrigo.position+Vector2(-21,-32)
	nome.add_theme_font_size_override("font_size",10)
	nome.add_theme_color_override("font_color",Color("#ffe4a3"))
	add_child(nome)
	var juntos := Label.new()
	juntos.text = "UMA PEDRA PARA CADA AMIGO"
	juntos.position = Vector2(93,117)
	juntos.add_theme_font_size_override("font_size",10)
	add_child(juntos)
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	aviso = Label.new()
	aviso.position = Vector2(12,48)
	aviso.add_theme_font_size_override("font_size",11)
	aviso.add_theme_color_override("font_shadow_color",Color.BLACK)
	aviso.add_theme_constant_override("shadow_offset_x",1)
	aviso.add_theme_constant_override("shadow_offset_y",1)
	canvas.add_child(aviso)
	abrigo.reached.connect(func(): avisar("Abrigo encontrado! A dupla volta para cá se cair."))
	_boas_vindas.call_deferred()

func _boas_vindas() -> void:
	while FluxoTela.em_transicao or HistoriaDupla.ativa:
		await get_tree().process_frame
	avisar("Sigam pelas salas. As duas pedras precisam de um amigo em cada uma.")

func avisar(texto: String) -> void:
	aviso.text = texto
	tempo_aviso = 4

func _process(delta: float) -> void:
	tempo += delta
	tempo_aviso = maxf(0,tempo_aviso-delta)
	aviso.modulate.a = clampf(tempo_aviso/0.5,0,1)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(abrigo): return
	var cor := Color("#93dbb5") if abrigo.is_active else Color("#e5c98b")
	cor.a = 0.3+sin(tempo*2)*0.08
	for i in 8:
		var angulo := float(i)*TAU/8
		var ponto := abrigo.position+Vector2.from_angle(angulo)*24
		draw_rect(Rect2(ponto.round(),Vector2(3,3)),cor)
