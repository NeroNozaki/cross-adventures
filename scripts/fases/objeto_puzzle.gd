@tool
extends StaticBody2D
## Modulo de puzzle: a configuracao e os sprites ficam editaveis na cena.

@export var config: Dictionary = {}
var fase: Node2D
var ativo: bool = false
var estado: String = ""
var movendo: bool = false
var equipe: int = 1
var vida_atual: int = 1
var esta_morto: bool = false
var altura_nivel: int = 0
var particulas: Array[Dictionary] = []
var tempo_visual: float = 0.0
var pressao_visual: float = 0.0
var abertura_visual: float = 0.0
var flash_ativacao: float = 0.0
var quadros_bau: Array[Rect2] = []
const BAUS: Texture2D = preload("res://assets/mapa/CRAFTPIX_DUNGEON/doors_lever_chest_animation.png")
const PORTA: Texture2D = preload("res://recursos/visual/porta_dungeon.tres")
signal mudou

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	fase = get_tree().get_first_node_in_group("fase_atual")
	altura_nivel = int(config.get("z", 0))
	estado = str(config.get("tipo", "caixa"))
	collision_layer = 1
	collision_mask = 0
	set_meta("altura", altura_nivel)
	_atualizar_solidez()
	if tipo()=="bau":
		var imagem: Image=BAUS.get_image()
		# Cada faixa de 48 px contém uma alavanca em cima e um baú embaixo.
		for i in range(5):
			var origem: Vector2i=Vector2i(132,i*48+16)
			var usado: Rect2i=imagem.get_region(Rect2i(origem,Vector2i(28,32))).get_used_rect()
			quadros_bau.append(Rect2(Vector2(origem+usado.position),Vector2(usado.size)))
	if tipo() in ["barril","caixa"]:
		var detalhes: Node2D=Node2D.new()
		detalhes.name="DetalhesDoMaterial"
		detalhes.set_script(preload("res://scripts/visual/prop_detalhes.gd"))
		add_child(detalhes)
	queue_redraw()

func tipo() -> String:
	return estado if not estado.is_empty() else str(config.get("tipo", "caixa"))

func _atualizar_solidez() -> void:
	var solido: bool = tipo() in ["bau", "caixa", "gelo", "agua", "porta", "espelho", "barreira_gelo", "planta", "barril", "receptor", "condutor", "bolha"]
	if tipo() == "porta" and ativo:
		solido = false
	if esta_morto or (ativo and tipo() in ["barreira_gelo", "bolha"]):
		solido = false
	if esta_morto and has_node("AreaDano"):
		$AreaDano.collision_layer = 0
	collision_layer = 1 if solido else 0
	if has_node("Colisao"):
		$Colisao.set_deferred("disabled", not solido)
	if has_node("Sprite"):
		$Sprite.visible = not esta_morto and not (tipo() == "porta" and ativo)

func definir_ativo(valor: bool) -> void:
	if valor == ativo:
		return
	ativo = valor
	flash_ativacao=1.0 if valor else 0.0
	if tipo()=="placa":
		var som: Node=get_node_or_null("/root/InterfaceAudio")
		if som!=null: som.tocar("abrir" if valor else "fechar")
	_atualizar_solidez()
	mudou.emit()
	queue_redraw()

func receber_projetil(tiro: Node2D) -> String:
	if esta_morto or (ativo and tipo() in ["barreira_gelo", "bolha"]):
		return "ignorar"
	if tiro.altura_nivel != altura_nivel:
		return "ignorar"
	var elemento: String = tiro.elemento
	match tipo():
		"receptor", "condutor":
			var minimo: int = int(config.get("ricochetes", 0))
			var pedido: String = str(config.get("elemento", "normal"))
			if tiro.ricochetes<minimo and fase.dados.numero==1:
				fase.avisar("O cristal precisa de um tiro refletido. Procure o ângulo do espelho; Tab mostra a trajetória.")
			if tiro.ricochetes >= minimo and (pedido == "normal" or pedido == elemento) and (not config.get("carregado", false) or tiro.carregado):
				if fase.condicao_receptor(config):
					definir_ativo(true)
					fase.sinalizar(str(config.get("sinal", name)), true)
			return "consumir"
		"agua", "bolha":
			if elemento == "gelo":
				estado = "gelo"
				config["empurravel"] = true
				_atualizar_solidez()
				queue_redraw()
			elif elemento == "onda":
				definir_ativo(true)
				collision_layer = 0
				if has_node("Colisao"):
					$Colisao.set_deferred("disabled", true)
				fase.sinalizar(str(config.get("sinal", name)), true)
			return "consumir"
		"gelo", "barreira_gelo":
			if elemento == "fogo":
				if tipo() == "gelo" and not config.has("sinal"):
					estado = "agua"
					config["empurravel"] = false
					_atualizar_solidez()
				else:
					definir_ativo(true)
					collision_layer = 0
					if has_node("Colisao"):
						$Colisao.set_deferred("disabled", true)
					fase.sinalizar(str(config.get("sinal", name)), true)
				queue_redraw()
				return "consumir"
			return "rebater"
		"planta", "barril":
			receber_dano(tiro.dano, tiro.global_position)
			return "consumir"
	return "rebater"

func receber_dano(_valor: int, _origem: Vector2) -> void:
	if esta_morto or tipo() not in ["planta", "barril"]:
		return
	esta_morto = true
	vida_atual = 0
	_atualizar_solidez()
	for i in range(9):
		particulas.append({"p": Vector2.ZERO, "v": Vector2.RIGHT.rotated(float(i) * TAU / 9.0) * randf_range(30, 65), "t": 0.65})
	mudou.emit()
	queue_redraw()

func interagir(ator: CharacterBody2D) -> bool:
	if ator.altura_nivel != altura_nivel or ator.esta_morto or ator.pulando:
		return false
	if tipo() == "bau":
		if ativo: return false
		definir_ativo(true)
		for heroi in [fase.lucas,fase.otto]:
			if heroi.esta_morto: continue
			heroi.vida_atual = mini(heroi.vida_maxima,heroi.vida_atual+30)
			heroi.barra_vida.value = heroi.vida_atual
			heroi.vida_alterada.emit(heroi.vida_atual,heroi.vida_maxima)
		fase.avisar("Provisões encontradas: +30 de vida para cada companheiro. O baú só pode ser aberto uma vez.")
		get_node("/root/InterfaceAudio").tocar("objetivo")
		return true
	if tipo() == "estacao":
		fase.otto.elemento = str(config.get("elemento", "normal"))
		fase.avisar("Otto selecionou " + str(config.get("elemento", "normal")).to_upper() + ".")
		return true
	if tipo() in ["caixa", "gelo"] and not movendo:
		if ator.nome_personagem != "Lucas":
			fase.avisar("Lucas pode empurrar este bloco com E.")
			return false
		if ator.global_position.distance_to(global_position) > 54 or ator.global_position.direction_to(global_position).dot(ator.frente) < 0.6:
			return false
		return empurrar(ator.frente)
	if tipo() == "placa_texto":
		fase.avisar(str(config.get("texto", "")), 6.0)
		return true
	return false

func empurrar(direcao: Vector2) -> bool:
	if movendo or fase == null:
		return false
	var destino: Vector2 = global_position + direcao * 32.0
	if not fase.pode_colocar_caixa(destino, altura_nivel, self):
		fase.avisar("O bloco precisa de uma casa livre na mesma altura.")
		return false
	movendo = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", destino, 0.18)
	tween.finished.connect(func(): movendo = false; mudou.emit())
	return true

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	tempo_visual += delta
	pressao_visual=move_toward(pressao_visual,1.0 if ativo else 0.0,delta*7)
	abertura_visual=move_toward(abertura_visual,1.0 if ativo else 0.0,delta*2)
	flash_ativacao=maxf(0.0,flash_ativacao-delta*1.5)
	if tipo() in ["agua","bolha","receptor","condutor","saida","estacao","placa","bau","planta"]:
		queue_redraw()
	var tinha_particulas: bool = not particulas.is_empty()
	for p in particulas:
		p.p += p.v * delta
		p.v *= 0.93
		p.t -= delta
	particulas = particulas.filter(func(p): return p.t > 0.0)
	if tinha_particulas:
		queue_redraw()

func _draw() -> void:
	var t: String = tipo()
	var off: Vector2 = Vector2(0, -16.0 * int(config.get("z", 0)))
	if t == "bau":
		draw_ellipse_local(off+Vector2(0,2),Vector2(18,5),Color(0.04,0.05,0.08,0.4))
		if not quadros_bau.is_empty():
			var r: Rect2=quadros_bau[mini(quadros_bau.size()-1,int(abertura_visual*(quadros_bau.size()-1)))]
			draw_texture_rect_region(BAUS,Rect2(off+Vector2(-r.size.x,-r.size.y*2),r.size*2),r)
		if flash_ativacao>0:
			for i in range(5):
				var p: Vector2=off+Vector2(-12+i*6,-32-(1-flash_ativacao)*20-sin(float(i))*4)
				draw_rect(Rect2(p.snapped(Vector2(2,2)),Vector2(2,2)),Color(0.98,0.82,0.48,flash_ativacao))
	elif t == "placa":
		var cor: Color=Color("8bc7b5") if ativo else Color("bd965c")
		var topo: Vector2=off+Vector2(0,roundf(pressao_visual)*2)
		# Pedra chanfrada, aro de bronze, sulcos e uma tampa que desce sob o peso.
		draw_colored_polygon(PackedVector2Array([off+Vector2(-20,-6),off+Vector2(-14,-14),off+Vector2(14,-14),off+Vector2(20,-6),off+Vector2(20,10),off+Vector2(14,16),off+Vector2(-14,16),off+Vector2(-20,10)]),Color("272c3a"))
		draw_rect(Rect2(off+Vector2(-16,-12),Vector2(32,24)),Color("6b6d77"))
		draw_rect(Rect2(off+Vector2(-14,-14),Vector2(28,4)),Color("a6a5a5"))
		draw_rect(Rect2(off+Vector2(-16,10),Vector2(32,4)),Color("414552"))
		for x in [-18,14]:
			draw_rect(Rect2(off+Vector2(x,-6),Vector2(4,14)),Color("464859"))
		for x in [-14,10]:
			for y in [-10,8]:
				draw_rect(Rect2(off+Vector2(x,y),Vector2(4,4)),Color("323341"))
				draw_rect(Rect2(off+Vector2(x,y),Vector2(2,2)),Color("c4b087"))
		draw_rect(Rect2(topo+Vector2(-12,-10),Vector2(24,22)),Color("322e37"))
		draw_rect(Rect2(topo+Vector2(-10,-10),Vector2(20,18)),cor.darkened(0.42))
		draw_rect(Rect2(topo+Vector2(-10,-10),Vector2(20,2)),cor.lightened(0.15))
		draw_rect(Rect2(topo+Vector2(-10,-8),Vector2(2,14)),cor.darkened(0.05))
		draw_rect(Rect2(topo+Vector2(8,-6),Vector2(2,14)),cor.darkened(0.6))
		for y in [-6,4]: draw_rect(Rect2(topo+Vector2(-6,y),Vector2(12,2)),cor.darkened(0.2))
		var runa: Color=Color("d6eee0") if ativo else Color("dfc590")
		if config.get("somente_caixa",false):
			draw_rect(Rect2(topo+Vector2(-4,-4),Vector2(8,8)),runa,false,2)
		else:
			for x in [-4,2]:
				draw_rect(Rect2(topo+Vector2(x,-4),Vector2(2,4)),runa)
				draw_rect(Rect2(topo+Vector2(x,2),Vector2(4,2)),runa)
		for x in [-18,14]: draw_rect(Rect2(off+Vector2(x,0),Vector2(4,4)),cor.lightened(0.25) if ativo else cor.darkened(0.5))
	elif t in ["receptor","condutor","estacao"]:
		var cor: Color=cor_elemento(str(config.get("elemento","normal")))
		draw_rect(Rect2(off+Vector2(-14,-2),Vector2(28,6)),Color("252734"))
		draw_rect(Rect2(off+Vector2(-12,-8),Vector2(24,8)),Color("626674"))
		draw_rect(Rect2(off+Vector2(-10,-8),Vector2(20,2)),Color("a4a9ae"))
		draw_rect(Rect2(off+Vector2(-8,-14),Vector2(16,8)),Color("454450"))
		draw_rect(Rect2(off+Vector2(-8,-14),Vector2(4,8)),Color("82848a"))
		# Pedestal em degraus e cintas de bronze, com faces e juntas de pedra.
		for x in [-12,8]:
			draw_rect(Rect2(off+Vector2(x,-6),Vector2(4,6)),Color("a58e67"))
			draw_rect(Rect2(off+Vector2(x,-6),Vector2(2,2)),Color("d9c297"))
		draw_rect(Rect2(off+Vector2(-6,-10),Vector2(12,2)),Color("303644"))
		var suspenso: float=roundf(sin(tempo_visual*1.5)*1.0)*2
		var centro: Vector2=off+Vector2(0,-25+suspenso)
		for i in range(3):
			var p: Vector2=off+Vector2(roundf(cos(tempo_visual*0.7+i*TAU/3)*14/2)*2,-22+roundf(sin(tempo_visual*0.7+i*TAU/3)*5/2)*2)
			draw_rect(Rect2(p,Vector2(2,2)),Color(cor,0.28+flash_ativacao*0.5))
		var brilho: float=1.0 if ativo else 0.72+sin(tempo_visual*2)*0.05
		draw_colored_polygon(PackedVector2Array([centro+Vector2(0,-12),centro+Vector2(10,0),centro+Vector2(0,12),centro+Vector2(-10,0)]),Color("252b3b"))
		draw_colored_polygon(PackedVector2Array([centro+Vector2(0,-10),centro+Vector2(8,0),centro+Vector2(0,10),centro+Vector2(-8,0)]),cor.darkened(0.42))
		draw_colored_polygon(PackedVector2Array([centro+Vector2(0,-10),centro+Vector2(0,10),centro+Vector2(-8,0)]),cor*Color(brilho,brilho,brilho,1))
		draw_colored_polygon(PackedVector2Array([centro+Vector2(0,-8),centro+Vector2(6,0),centro+Vector2(0,-2),centro+Vector2(-4,0)]),cor.lightened(0.4))
		draw_rect(Rect2(centro+Vector2(-2,-6),Vector2(2,4)),Color("dce9e0"))
		if ativo: draw_rect(Rect2(off+Vector2(-8,-4),Vector2(16,2)),cor)
		if int(config.get("ricochetes",0))>0:
			draw_polyline(PackedVector2Array([off+Vector2(-6,-39),off+Vector2(0,-43),off+Vector2(6,-39)]),Color("d5c18a"),2)
		if config.get("carregado",false):
			draw_rect(Rect2(off+Vector2(-16,-12),Vector2(4,6)),cor.darkened(0.2))
			draw_rect(Rect2(off+Vector2(12,-12),Vector2(4,6)),cor.darkened(0.2))
	elif t in ["agua","gelo","barreira_gelo","bolha"]:
		var gelado: bool=t in ["gelo","barreira_gelo"]
		var cor: Color=Color("92c5d2") if gelado else Color("4d91ac")
		if ativo and t in ["barreira_gelo","bolha"]: cor.a=0.17
		if gelado:
			draw_rect(Rect2(off+Vector2(-14,-27),Vector2(28,29)),Color("273745"))
			draw_rect(Rect2(off+Vector2(-12,-27),Vector2(24,25)),cor)
			draw_rect(Rect2(off+Vector2(-10,-25),Vector2(20,21)),Color(0.8,0.95,1,0.3),false,1)
			draw_line(off+Vector2(-7,-22),off+Vector2(4,-10),Color("d5e8e7"),2)
			draw_line(off+Vector2(-3,-8),off+Vector2(7,-20),Color("c1e4e6"),1)
		else:
			draw_ellipse_local(off,Vector2(15,7),Color("202536"))
			draw_ellipse_local(off+Vector2(0,-8),Vector2(12,12),Color(cor,0.65))
			draw_arc(off+Vector2(0,-8),11,PI*1.1,PI*1.7,12,Color("9ec9d4"),2)
			draw_line(off+Vector2(-6,-7+sin(tempo_visual*3)),off+Vector2(7,-7+sin(tempo_visual*3)),Color("9ec9d4"),1)
	elif t == "espelho":
		draw_rect(Rect2(-30,-11,60,14),Color("17141e"))
		draw_rect(Rect2(-29,-10,58,12),Color("a38b69"))
		draw_rect(Rect2(-25,-8,50,8),Color("537c91"))
		draw_line(Vector2(-24,-7),Vector2(24,-7),Color("c0d9d8"),2)
		for x in [-27,27]: draw_circle(Vector2(x,-4),1,Color("d9c695"))
	elif t in ["barril","caixa"] and not esta_morto:
		draw_ellipse_local(off+Vector2(0,1),Vector2(15,5),Color(0.04,0.05,0.08,0.42))
	elif t == "placa_texto":
		draw_rect(Rect2(off+Vector2(-2,-12),Vector2(4,16)),Color("493634"))
		draw_rect(Rect2(off+Vector2(-14,-28),Vector2(28,18)),Color("332c35"))
		draw_rect(Rect2(off+Vector2(-12,-26),Vector2(24,14)),Color("8a654d"))
		draw_rect(Rect2(off+Vector2(-12,-26),Vector2(24,2)),Color("c49965"))
		draw_rect(Rect2(off+Vector2(-12,-14),Vector2(24,2)),Color("5d403a"))
		for x in [-10,8]: draw_rect(Rect2(off+Vector2(x,-22),Vector2(2,2)),Color("d5b37a"))
		for y in [-22,-18]: draw_rect(Rect2(off+Vector2(-6,y),Vector2(12,2)),Color("d4bb88"))
		# Veios da madeira, extremidades reforçadas e pé apoiado no chão.
		for p: Vector2 in [Vector2(-10,-17),Vector2(4,-24),Vector2(-6,-15)]:
			draw_rect(Rect2(off+p,Vector2(4,1)),Color("664c40"))
		for x in [-14,10]:
			draw_rect(Rect2(off+Vector2(x,-26),Vector2(4,14)),Color("535260"))
			draw_rect(Rect2(off+Vector2(x,-26),Vector2(2,2)),Color("b3aaa0"))
		draw_rect(Rect2(off+Vector2(-4,2),Vector2(8,2)),Color("37333d"))
	elif t == "planta" and not esta_morto:
		# Folhagem em pixels inteiros: contorno, folhas sobrepostas, nervuras e vaso sombreado.
		var desenho: Array[String]=[
			"        dd        ",
			"   dd   dl   dd   ",
			"  dggd  dl  dggd  ",
			"  dhlgd dl dglhd  ",
			"   dhggddl dggd   ",
			"    ddggdldggd    ",
			" dd   ddglgdd   dd",
			"dggd   dglgd   dgd",
			"dhlggdddglgdddggld",
			" dhhgggdlglgggghd ",
			"  ddddgglggdddd   ",
			"    ddglllggd     ",
			"     dgglgdd      ",
			"      ddld        ",
			"    bbbbbbbb      ",
			"    btttttsb      ",
			"     btttsb       ",
			"     bttssb       ",
			"      bbbb        "]
		var paleta: Dictionary={"d":Color("243a35"),"g":Color("3e6748"),"l":Color("76915c"),"h":Color("a5ad70"),"b":Color("413537"),"t":Color("9d7159"),"s":Color("6e4e46")}
		for y in range(desenho.size()):
			for x in range(desenho[y].length()):
				var pixel: String=desenho[y][x]
				if paleta.has(pixel):
					var vento: float=2.0 if y<12 and sin(tempo_visual*0.9+float(config.get("x",0)))>0.72 else 0.0
					draw_rect(Rect2(off+Vector2((x-9)*2+vento,(y-19)*2),Vector2(2,2)),paleta[pixel])
	elif t == "porta":
		if not ativo: draw_texture_rect(PORTA,Rect2(off+Vector2(-32,-80),Vector2(64,96)),false)
	elif t == "saida":
		draw_texture_rect(PORTA,Rect2(off+Vector2(-32,-80),Vector2(64,96)),false,Color("b7c1c0"))
		var c: Color=Color("89cbb8") if ativo else Color("666078")
		draw_ellipse_local(off+Vector2(0,-1),Vector2(23,8),Color(c,0.15))
		draw_arc(off+Vector2(0,-17),13,PI,TAU,20,c,2)
		draw_circle(off+Vector2(0,-15),3,c)
	for p in particulas:
		draw_rect(Rect2(p.p + off, Vector2(3, 3)), Color(0.66,0.48,0.3,p.t/0.65) if t=="barril" else Color(0.5,0.67,0.36,p.t/0.65))

func _caixa(cor: Color) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = cor
	s.border_color = cor.lightened(0.4)
	s.set_border_width_all(2)
	s.set_corner_radius_all(4)
	return s

func draw_ellipse_local(p: Vector2, escala: Vector2, cor: Color) -> void:
	draw_set_transform(p, 0, escala)
	draw_circle(Vector2.ZERO, 1, cor)
	draw_set_transform(Vector2.ZERO)

static func cor_elemento(elemento: String) -> Color:
	match elemento:
		"fogo": return Color("ff9a61")
		"gelo": return Color("83e2ff")
		"choque": return Color("cfabff")
		"onda": return Color("6af3c0")
	return Color("75e5ef")
