extends Node2D
const PEDRA=preload("res://assets/mapa/CRAFTPIX_DUNGEON/walls_floor.png")
const SOM=preload("res://assets/SONS/CENARIO/PONTE/ponte_mecanismo.wav")
const DURACAO: float=1.8
var fase: Node2D
var tempo: float=0.0
var pronta: bool=false
var iniciada: bool=false
var disparos_som: int=0
var audio: AudioStreamPlayer2D
signal terminou
func _ready() -> void:
	fase=get_parent()
	audio=AudioStreamPlayer2D.new()
	audio.name="SomDaPonte"
	audio.stream=SOM
	audio.bus="SFX"
	audio.position=Vector2(432,672)
	audio.max_distance=1400
	audio.volume_db=-10
	add_child(audio)
func avancar(delta: float) -> void:
	if not fase.sinais.get("ponte",false):
		tempo=0.0; pronta=false; iniciada=false
		if audio.playing: audio.stop()
		return
	if not iniciada:
		iniciada=true
		disparos_som+=1
		audio.play()
	if pronta: return
	tempo=minf(DURACAO,tempo+delta)
	if tempo>=DURACAO:
		pronta=true
		terminou.emit()
func _process(delta: float) -> void:
	avancar(delta)
	queue_redraw()
func _draw() -> void:
	# Encontros de pedra nas duas margens, sem bloquear o centro da passagem.
	for x in [376,488]:
		for y in [638,706]:
			draw_rect(Rect2(x-8,y-4,16,8),Color("303342"))
			draw_rect(Rect2(x-6,y-8,12,8),Color("646777"))
			draw_rect(Rect2(x-6,y-8,12,2),Color("a5a5a3"))
			draw_rect(Rect2(x-2,y-12,4,4),Color("91ceb8") if pronta else Color("ab9061"))
	if not iniciada: return
	for i in range(3):
		var t: float=clampf((tempo-0.25-float(i)*0.36)/0.6,0,1)
		if t<=0: continue
		var sobe: float=1-pow(1-t,3)
		var y: float=640+roundf((1-sobe)*10)*2
		var x: float=384+i*32
		var cor: Color=Color(0.84,0.91,0.96,0.35+sobe*0.65)
		# Face abaixo do tabuleiro e vãos dos pequenos arcos.
		draw_rect(Rect2(x,y+62,32,14),Color(0.19,0.21,0.29,cor.a))
		draw_rect(Rect2(x+2,y+64,28,2),Color(0.51,0.53,0.58,cor.a))
		draw_rect(Rect2(x+8,y+70,16,6),Color(0.06,0.13,0.18,cor.a))
		draw_rect(Rect2(x+12,y+68,8,4),Color(0.06,0.13,0.18,cor.a))
		for linha in range(2):
			draw_texture_rect_region(PEDRA,Rect2(x,y+linha*32,32,32),Rect2(32,128,16,16),cor)
			draw_rect(Rect2(x+2,y+linha*32+28,28,2),Color(0.23,0.25,0.33,cor.a*0.6))
		# Lajes intercaladas, chanfros claros e juntas escuras distinguem o tabuleiro do chão.
		for fileira in range(4):
			var yy: float=y+8+fileira*12
			var tom: Color=Color(0.39+float((i+fileira)%2)*0.025,0.43+float(fileira%2)*0.02,0.53,cor.a)
			draw_rect(Rect2(x+2,yy,28,10),tom)
			draw_rect(Rect2(x+4,yy,24,2),Color(0.53,0.56,0.62,cor.a*0.6))
			var junta: float=x+(12 if fileira%2==0 else 22)
			draw_rect(Rect2(junta,yy,2,10),Color(0.22,0.25,0.33,cor.a*0.65))
		for bordo in [2,58]:
			draw_rect(Rect2(x,y+bordo,32,4),Color(0.24,0.26,0.34,cor.a))
			draw_rect(Rect2(x+2,y+bordo,28,2),Color(0.65,0.59,0.44,cor.a))
			for furo in [6,22]: draw_rect(Rect2(x+furo,y+bordo,2,2),Color(0.84,0.76,0.55,cor.a))
		if t<1:
			# Respingos curtos junto às peças que saem da água.
			for j in range(5):
				var p: Vector2=Vector2(x+4+j*6,y+60+roundf(sin(t*PI+float(j))*4)*2)
				draw_rect(Rect2(p,Vector2(2,2)),Color(0.55,0.81,0.81,(1-t)*0.55))
