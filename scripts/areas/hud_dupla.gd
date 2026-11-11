extends CanvasLayer
## Cartões locais da masmorra, ligados à vida real dos heróis.
func _ready() -> void:
	layer = 21
	var linha := HBoxContainer.new()
	linha.position = Vector2(8,8)
	linha.add_theme_constant_override("separation",5)
	add_child(linha)
	var sala := get_parent()
	for i in 2:
		var heroi = sala.player1 if i == 0 else sala.player2
		var painel := PanelContainer.new()
		painel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		painel.custom_minimum_size = Vector2(91,42)
		painel.add_theme_stylebox_override("panel",Convivencia.moldura_pixel())
		linha.add_child(painel)
		var conteudo := HBoxContainer.new()
		conteudo.add_theme_constant_override("separation",4)
		painel.add_child(conteudo)
		conteudo.add_child(Convivencia._foto(i,24))
		var coluna := VBoxContainer.new()
		coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		coluna.add_theme_constant_override("separation",2)
		conteudo.add_child(coluna)
		var nome := Label.new()
		nome.text = "LUCAS" if i == 0 else "OTTO"
		nome.add_theme_font_override("font",load("res://assets/INTERFACE/FONTES/TINY5/Tiny5.ttf"))
		nome.add_theme_font_size_override("font_size",12)
		nome.add_theme_color_override("font_color",Color("#f4cf83") if i == 0 else Color("#84e0ed"))
		coluna.add_child(nome)
		var vida := ProgressBar.new()
		vida.show_percentage = false
		vida.custom_minimum_size = Vector2(43,6)
		var fundo := StyleBoxTexture.new()
		fundo.texture = load("res://assets/Ninja Adventure - Asset Pack/Ui/Receptacle/LifeBarMiniUnder.png")
		fundo.texture_margin_left = 1
		fundo.texture_margin_right = 1
		vida.add_theme_stylebox_override("background",fundo)
		var cor := StyleBoxFlat.new()
		cor.bg_color = Color("#e6b26d") if i == 0 else Color("#62d4dc")
		cor.set_content_margin_all(1)
		vida.add_theme_stylebox_override("fill",cor)
		vida.max_value = heroi.vida_maxima
		vida.value = heroi.vida_atual
		coluna.add_child(vida)
		heroi.vida_alterada.connect(func(atual: int, maxima: int):
			vida.max_value = maxima
			vida.value = atual)
		heroi.get_node("BarraVida").hide()
