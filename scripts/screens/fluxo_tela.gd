extends CanvasLayer
## Íris em forma de cristal, em degraus de pixels e sem flashes.
var em_transicao := false
var progresso := 0.0
var cortina: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200
	cortina = Control.new()
	cortina.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	cortina.draw.connect(_desenhar)
	add_child(cortina)
	cortina.hide()

func _input(_event: InputEvent) -> void:
	if em_transicao:
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if em_transicao:
		cortina.queue_redraw()

func _desenhar() -> void:
	var tamanho := get_viewport().get_visible_rect().size
	var centro_x := tamanho.x * 0.5
	var raio := pow(1.0 - progresso, 1.2) * (tamanho.x + tamanho.y) * 0.5
	for y in range(0, ceili(tamanho.y), 8):
		var abertura := maxf(0, raio - absf(float(y) + 4.0 - tamanho.y * 0.5))
		var borda := ceilf(centro_x) if abertura <= 0 else clampf(floorf((centro_x - abertura) / 4.0) * 4.0, 0, centro_x)
		cortina.draw_rect(Rect2(0, y, borda, 8), Color("111c29"))
		cortina.draw_rect(Rect2(tamanho.x - borda, y, borda, 8), Color("111c29"))
		if borda > 0 and borda < centro_x:
			cortina.draw_rect(Rect2(borda - 1, y, 1, 8), Color("647d85"))
			cortina.draw_rect(Rect2(tamanho.x - borda, y, 1, 8), Color("647d85"))
	if progresso > 0.92:
		var centro := (tamanho * 0.5).round()
		var alfa := (progresso - 0.92) / 0.08 * 0.8
		cortina.draw_polyline(PackedVector2Array([centro + Vector2(0,-8), centro + Vector2(8,0), centro + Vector2(0,8), centro + Vector2(-8,0), centro + Vector2(0,-8)]), Color(0.87,0.76,0.48,alfa), 1)

func trocar(caminho: String) -> void:
	if em_transicao:
		return
	if not ResourceLoader.exists(caminho):
		push_error("Cena de destino ausente: " + caminho)
		return
	em_transicao = true
	progresso = 0.0
	cortina.show()
	get_tree().paused = true
	var tween := create_tween()
	tween.tween_property(self, "progresso", 1.0, 0.28).set_trans(Tween.TRANS_SINE)
	await tween.finished
	var resultado := get_tree().change_scene_to_file(caminho)
	if resultado == OK:
		await get_tree().process_frame
		await get_tree().create_timer(0.08).timeout
	else:
		push_error("Não foi possível abrir a cena: " + caminho)
	tween = create_tween()
	tween.tween_property(self, "progresso", 0.0, 0.36).set_trans(Tween.TRANS_SINE)
	await tween.finished
	cortina.hide()
	em_transicao = false
	get_tree().paused = false
