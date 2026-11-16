extends Node2D
const MAPAS = preload("res://recursos/mapas_puzzle.gd")
var tempo := 0.0

func _process(delta: float) -> void:
	tempo += delta
	queue_redraw()

func _draw() -> void:
	var sala := get_parent()
	var dados: Dictionary = MAPAS.FASES[sala.mapa_id]
	# A parede projeta uma pequena sombra no piso, com a mesma largura do tile.
	var piso: TileMapLayer = sala.get_node("Piso")
	var paredes: TileMapLayer = sala.get_node("Paredes")
	for celula: Vector2i in paredes.get_used_cells():
		if piso.get_cell_source_id(celula+Vector2i.DOWN) >= 0:
			draw_rect(Rect2(Vector2(celula+Vector2i.DOWN)*24,Vector2(24,6)),Color(0,0,0,0.24))
	# Sombra de contato e espuma ficam limitadas ao retângulo de cada tanque.
	for tanque: Rect2i in dados.agua:
		var area := Rect2(Vector2(tanque.position)*24,Vector2(tanque.size)*24)
		draw_rect(Rect2(area.position,Vector2(area.size.x,5)),Color(0,0,0,0.30))
		draw_rect(Rect2(area.position,Vector2(4,area.size.y)),Color(0,0,0,0.22))
		for i in 5:
			var x: float = area.position.x+12+fmod(i*31+tempo*4,area.size.x-24)
			var y: float = area.position.y+7+fmod(i*43,maxf(1,area.size.y-14))
			if sala.mapa_id == 2 and sala.resolvida and Rect2(Vector2(dados.ponte.position)*24,Vector2(dados.ponte.size)*24).grow(10).has_point(Vector2(x,y)):
				continue
			draw_line(Vector2(x,y).round(),Vector2(x+8,y).round(),Color(0.4,0.8,0.9,0.15),1)
		# Uma gota distante cria uma ondulação que cresce e desaparece.
		var ciclo := fmod(tempo+tanque.position.y*0.3,4.8)
		var ponto := area.get_center()+Vector2(sin(float(tanque.position.x))*area.size.x*0.18,cos(float(tanque.position.y))*area.size.y*0.18)
		var na_ponte: bool = sala.mapa_id == 2 and sala.resolvida and Rect2(Vector2(dados.ponte.position)*24,Vector2(dados.ponte.size)*24).grow(20).has_point(ponto)
		if not na_ponte:
			draw_arc(ponto,minf(2+ciclo*3,minf(area.size.x,area.size.y)*0.27),0,TAU,20,Color(0.55,0.88,0.95,maxf(0,0.28-ciclo*0.07)),1)
	if sala.mapa_id == 4:
		var inicio := Vector2(dados.tiro)*24+Vector2(12,12)
		var espelho := Vector2(dados.espelho)*24+Vector2(12,12)
		for x in range(int(inicio.x),int(espelho.x)-12,12):
			draw_rect(Rect2(x,inicio.y,4,1),Color(0.4,0.8,0.85,0.35))
		for y in range(int(Vector2(dados.alvos[0]).y*24+12),int(espelho.y)-12,14):
			draw_rect(Rect2(espelho.x,y,1,4),Color(0.4,0.8,0.85,0.22))
	if sala.mapa_id == 2:
		# Três luzes de encaixe indicam o avanço sem exigir a leitura do contador.
		for i in 3:
			var ponto := Vector2(dados.ponte.position)*24+Vector2(-8,12+i*24)
			draw_rect(Rect2(ponto-Vector2(4,4),Vector2(8,8)),Color("#252b3b"))
			draw_rect(Rect2(ponto-Vector2(2,2),Vector2(4,4)),Color("#ffe7a2") if sala.progresso > i else Color("#607c8f"))
	# Pedras de saída emitem luz somente depois da resolução.
	if sala.pronta:
		var centro := Vector2(dados.saida)*24+Vector2(12,12)
		draw_arc(centro,28+sin(tempo*2)*2,0,TAU,32,Color(1,0.86,0.55,0.4),2)
