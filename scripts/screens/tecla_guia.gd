extends Control
## Diagramas do teclado e mouse usando os ícones originais do projeto.
const PASTA = "res://assets/Ninja Adventure - Asset Pack/Ui/Input/"
var tipo := ""
var acao := ""
var icones: Array[Dictionary] = []
var previa := 0.0
var carga := 0.0
var tempo := 0.0

func configurar(modo: String, comando: String = "") -> void:
	tipo = modo
	acao = comando
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(94,50 if modo in ["lucas","otto"] else 32)
	# Cada ação precisa ter uma área própria: sem isso os dois exemplos do
	# botão esquerdo podem receber o mesmo clique quando ficam empilhados.
	if modo not in ["lucas","otto"]:
		custom_minimum_size = Vector2(100,32)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Experimente a tecla ou clique no desenho."
	if modo in ["lucas","otto"]:
		var prefixo := "player1_" if modo == "lucas" else "player2_"
		for direcao in ["cima","esquerda","baixo","direita"]:
			_adicionar_tecla(prefixo+direcao)
	elif modo == "tecla":
		_adicionar_tecla(comando)
	else:
		var arquivo := "Mouse.png"
		if modo in ["mouse_esquerdo","segurar"]:
			arquivo = "MouseButtonLeft.png"
		elif modo == "mouse_direito":
			arquivo = "MouseButtonRight.png"
		icones.append({"textura":load(PASTA+"Mouse/"+arquivo)})

func _adicionar_tecla(comando: String) -> void:
	for evento in InputMap.action_get_events(comando):
		if evento is InputEventKey:
			var codigo: int = evento.physical_keycode if evento.physical_keycode else evento.keycode
			var nome := OS.get_keycode_string(codigo)
			var numerica := nome.begins_with("Kp ")
			var arquivo := nome.trim_prefix("Kp ")
			var caminho := PASTA+"Keyboard/Key"+arquivo+".png"
			var imagem: Texture2D = load(caminho) if ResourceLoader.exists(caminho) else null
			icones.append({"textura":imagem,"nome":nome,"numerica":numerica,"acao":comando})
			return

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	tempo += delta
	previa = maxf(0,previa-delta)
	# O disparo e a carga usam a mesma ação do jogo, mas são demonstrações
	# diferentes. O cartão de disparo não deve acender junto com o de carga.
	var acao_apertada := not acao.is_empty() and Input.is_action_pressed(acao)
	if tipo in ["mouse_esquerdo", "segurar", "mouse_direito"]:
		acao_apertada = false
	var apertado := previa > 0 or acao_apertada
	carga = minf(1,carga+delta/0.85) if apertado else 0.0
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		previa = 1.0 if tipo == "segurar" else 0.25
		accept_event()

func _desenhar_icone(item: Dictionary, centro: Vector2, demonstrar: bool) -> void:
	var apertado: bool = demonstrar
	if item.has("acao"):
		apertado = apertado or Input.is_action_pressed(item.acao)
	var textura: Texture2D = item.textura
	var cor := Color("#ffd984") if apertado else Color.WHITE
	var deslocamento := Vector2(0,2) if apertado else Vector2.ZERO
	if textura:
		var dimensao := textura.get_size()*1.5
		draw_texture_rect(textura,Rect2((centro-dimensao/2+deslocamento).round(),dimensao),false,cor)
	else:
		draw_rect(Rect2(centro-Vector2(14,12),Vector2(28,24)),Color("#bfc6a5"))
		draw_string(ThemeDB.fallback_font,centro+Vector2(-8,4),item.get("nome","?"),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#18262c"))

func _draw() -> void:
	if icones.is_empty():
		return
	var acao_apertada := not acao.is_empty() and Input.is_action_pressed(acao)
	if tipo in ["mouse_esquerdo", "segurar", "mouse_direito"]:
		acao_apertada = false
	var apertado := previa > 0 or acao_apertada
	if tipo in ["lucas","otto"]:
		var centros := [Vector2(47,12),Vector2(21,36),Vector2(47,36),Vector2(73,36)]
		for i in icones.size():
			_desenhar_icone(icones[i],centros[i],previa > 0 and int(tempo*6)%4==i)
	else:
		var centro := Vector2(42,16)
		_desenhar_icone(icones[0],centro,apertado)
		if tipo == "segurar":
			draw_rect(Rect2(72,7,5,25),Color("#07141d"))
			draw_rect(Rect2(73,31-carga*23,3,carga*23),Color("#6ee1e4"))
		elif tipo == "mouse_mira":
			var mira := Vector2(76+sin(tempo*2)*5,16+cos(tempo*2)*5)
			draw_circle(mira,5,Color("#74dce1"),false,1)
			draw_line(mira-Vector2(8,0),mira+Vector2(8,0),Color("#74dce1"),1)
			draw_line(mira-Vector2(0,8),mira+Vector2(0,8),Color("#74dce1"),1)
		elif tipo == "tecla" and icones[0].get("numerica",false):
			draw_string(ThemeDB.fallback_font,Vector2(64,21),"num.",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("#d5d6ba"))
