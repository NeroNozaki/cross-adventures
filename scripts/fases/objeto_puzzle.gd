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
	queue_redraw()

func tipo() -> String:
	return estado if not estado.is_empty() else str(config.get("tipo", "caixa"))

func _atualizar_solidez() -> void:
	var solido: bool = tipo() in ["caixa", "gelo", "agua", "porta", "espelho", "barreira_gelo", "planta", "barril", "receptor", "condutor", "bolha"]
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
	if ator.altura_nivel != altura_nivel:
		return false
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
	if tipo() in ["agua","bolha","receptor","condutor","saida","estacao"]:
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
	if t == "placa":
		var cor: Color=Color("9cd7b6") if ativo else Color("c4a165")
		draw_rect(Rect2(off+Vector2(-16,-10),Vector2(32,24)),Color("242a34"))
		draw_rect(Rect2(off+Vector2(-16,-12),Vector2(32,22)),Color("626779"))
		draw_rect(Rect2(off+Vector2(-14,-12),Vector2(28,2)),Color("a5aab2"))
		draw_rect(Rect2(off+Vector2(-14,-10),Vector2(26,18)),Color("8d918e"))
		draw_rect(Rect2(off+Vector2(-12,-8),Vector2(24,16)),Color("49414a"))
		draw_rect(Rect2(off+Vector2(-10,-8),Vector2(20,14)),cor.darkened(0.45))
		draw_rect(Rect2(off+Vector2(-10,-8),Vector2(20,2)),cor)
		for x in [-12,10]:
			for y in [-10,6]: draw_rect(Rect2(off+Vector2(x,y),Vector2(2,2)),Color("d0bd8a"))
		if config.get("somente_caixa",false):
			draw_rect(Rect2(off+Vector2(-4,-4),Vector2(8,8)),cor,false,2)
		else:
			draw_rect(Rect2(off+Vector2(-4,-4),Vector2(4,6)),cor)
			draw_rect(Rect2(off+Vector2(2,-2),Vector2(4,6)),cor)
	elif t in ["receptor","condutor","estacao"]:
		var cor: Color=cor_elemento(str(config.get("elemento","normal")))
		draw_rect(Rect2(off+Vector2(-14,-2),Vector2(28,6)),Color("252734"))
		draw_rect(Rect2(off+Vector2(-12,-8),Vector2(24,8)),Color("626674"))
		draw_rect(Rect2(off+Vector2(-10,-8),Vector2(20,2)),Color("a4a9ae"))
		draw_rect(Rect2(off+Vector2(-8,-14),Vector2(16,8)),Color("454450"))
		draw_rect(Rect2(off+Vector2(-8,-14),Vector2(4,8)),Color("82848a"))
		var centro: Vector2=off+Vector2(0,-23)
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
	elif t == "placa_texto":
		draw_rect(Rect2(off+Vector2(-2,-12),Vector2(4,16)),Color("493634"))
		draw_rect(Rect2(off+Vector2(-14,-28),Vector2(28,18)),Color("332c35"))
		draw_rect(Rect2(off+Vector2(-12,-26),Vector2(24,14)),Color("8a654d"))
		draw_rect(Rect2(off+Vector2(-12,-26),Vector2(24,2)),Color("c49965"))
		draw_rect(Rect2(off+Vector2(-12,-14),Vector2(24,2)),Color("5d403a"))
		for x in [-10,8]: draw_rect(Rect2(off+Vector2(x,-22),Vector2(2,2)),Color("d5b37a"))
		for y in [-22,-18]: draw_rect(Rect2(off+Vector2(-6,y),Vector2(12,2)),Color("d4bb88"))
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
				if paleta.has(pixel): draw_rect(Rect2(off+Vector2((x-9)*2,(y-19)*2),Vector2(2,2)),paleta[pixel])
	elif t == "porta":
		if not ativo: draw_texture_rect(PORTA,Rect2(off+Vector2(-32,-80),Vector2(64,96)),false)
	elif t == "saida":
		draw_texture_rect(PORTA,Rect2(off+Vector2(-32,-80),Vector2(64,96)),false,Color("b7c1c0"))
		var c: Color=Color("89cbb8") if ativo else Color("666078")
		draw_ellipse_local(off+Vector2(0,-1),Vector2(23,8),Color(c,0.15))
		draw_arc(off+Vector2(0,-17),13,PI,TAU,20,c,2)
		draw_circle(off+Vector2(0,-15),3,c)
	for p in particulas:
		draw_rect(Rect2(p.p + off, Vector2(3, 3)), Color(0.75, 0.8, 0.4, p.t / 0.65))

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
