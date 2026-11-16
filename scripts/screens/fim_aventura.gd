extends Control
func _ready() -> void:
	var fundo := TextureRect.new()
	fundo.texture = load("res://assets/INTERFACE/capa_nico_otto.png")
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.modulate = Color(0.32,0.4,0.45)
	add_child(fundo)
	var painel := PanelContainer.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	painel.offset_left = -225
	painel.offset_right = 225
	painel.offset_top = -90
	painel.offset_bottom = 90
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.02,0.06,0.09,0.93)
	estilo.border_color = Color("#d1b46e")
	estilo.set_border_width_all(2)
	estilo.set_content_margin_all(18)
	painel.add_theme_stylebox_override("panel",estilo)
	add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation",14)
	painel.add_child(coluna)
	for frase in ["Vocês escaparam!","Quatro desafios. Muitas ideias. Uma grande amizade.","Nico e Otto descobriram: juntos, podemos ir mais longe!"]:
		var label := Label.new()
		label.text = frase
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",22 if frase == "Vocês escaparam!" else 13)
		coluna.add_child(label)
	var voltar := Button.new()
	voltar.text = "Voltar ao menu"
	voltar.custom_minimum_size.y = 32
	for estado in ["normal","hover","pressed","focus"]:
		var placa := StyleBoxTexture.new()
		placa.texture = load("res://assets/INTERFACE/botao_reliquia.svg")
		placa.texture_margin_left = 15
		placa.texture_margin_right = 15
		placa.texture_margin_top = 5
		placa.texture_margin_bottom = 5
		placa.modulate_color = Color(1.2,1.15,1) if estado in ["hover","focus"] else Color.WHITE
		voltar.add_theme_stylebox_override(estado,placa)
	voltar.pressed.connect(func(): FluxoTela.trocar("res://cenas/screens/start_menu.tscn"))
	coluna.add_child(voltar)
	voltar.grab_focus()
