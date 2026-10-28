extends Node2D
## Acabamento e leitura espacial exclusivos da primeira fase.
const UI=preload("res://scripts/visual/tema_pixel.gd")
var fase: Node2D
var tempo: float=0.0
var musgo: Array[Rect2]=[]
func _ready() -> void:
	fase=get_parent()
	call_deferred("preparar")
func preparar() -> void:
	for c: Vector2i in fase.grade:
		if fase.grade[c]!=0: continue
		if fase.grade.has(c+Vector2i.UP) and fase.grade.has(c+Vector2i.LEFT): continue
		for i in range(5):
			var n: int=absi(c.x*1777+c.y*131+i*97)
			var p: Vector2=Vector2(c)*32+Vector2(posmod(n,15)*2,2+posmod(n/7,4)*2)
			musgo.append(Rect2(p,Vector2(2+posmod(n,3)*2,2)))
	queue_redraw()
func _process(delta: float) -> void:
	tempo+=delta
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(fase) or fase.dados.is_empty(): return
	# Juntas e pedra gasta na malha de 2 px; mecanismos preservam o maior contraste.
	for c: Vector2i in fase.grade:
		if int(fase.grade[c])!=0: continue
		var p: Vector2=Vector2(c)*32
		if fase.grade.has(c+Vector2i.DOWN):
			draw_rect(Rect2(p+Vector2(2,30),Vector2(28,2)),Color(0.12,0.15,0.21,0.14))
		if posmod(c.x+c.y,2)==0:
			draw_rect(Rect2(p+Vector2(16,2),Vector2(2,26)),Color(0.12,0.15,0.21,0.08))
	for i in range(musgo.size()):
		draw_rect(musgo[i],[Color("475b51"),Color("657359"),Color("80876b")][i%3])
	var placa: Node2D=fase.get_node("Objetos/PlacaA")
	var cristal: Node2D=fase.get_node("Objetos/Cristal")
	var cor: Color=Color("87cbb1") if fase.sinais.get("ponte",false) else Color("b1a06c")
	var fio: Color=Color("87cbb1") if fase.sinais.get("placa_a",false) or fase.sinais.get("ponte",false) else Color("8e7956")
	var trilho: PackedVector2Array=PackedVector2Array([placa.position+Vector2(16,0),Vector2(208,592),Vector2(208,336),Vector2(272,336),Vector2(272,192),cristal.position+Vector2(0,16)])
	for i in range(1,trilho.size()):
		draw_line(trilho[i-1]+Vector2(0,2),trilho[i]+Vector2(0,2),Color("343944"),4)
		draw_dashed_line(trilho[i-1],trilho[i],Color(fio,0.55),2,6)
	# Marca de tiro discreta e linha gravada até o espelho, sem resolver a mira pelo jogador.
	draw_arc(Vector2(176,272),8,0,TAU,16,Color("a99b75"),1)
	draw_line(Vector2(188,272),Vector2(254,272),Color(0.65,0.6,0.43,0.3),2)
	# Setas gravadas, sem cobrir a água ou criar obstáculos invisíveis.
	for p: Vector2 in [Vector2(208,512),Vector2(336,672),Vector2(528,672),Vector2(912,608),Vector2(976,400)]:
		var cima: bool=p.x>950 or p==Vector2(208,512)
		for n in range(3):
			var a: Vector2=Vector2(-4+n*2,-4+n*2) if cima else Vector2(-4+n*2,-4+n*2)
			var b: Vector2=Vector2(4-n*2,-4+n*2) if cima else Vector2(-4+n*2,4-n*2)
			draw_rect(Rect2(p+a,Vector2(2,2)),Color(cor,0.65))
			draw_rect(Rect2(p+b,Vector2(2,2)),Color(cor,0.65))
	for ator in [fase.lucas,fase.otto]:
		var obj: Node2D=fase.alvo_interacao(ator)
		if obj==null: continue
		var tecla: String="E" if ator==fase.lucas else "I"
		var texto: String=tecla+"  "+("ABRIR" if obj.tipo()=="bau" else ("LER" if obj.tipo()=="placa_texto" else "USAR"))
		var p: Vector2=obj.position+Vector2(-24,-48-obj.altura_nivel*16)
		draw_style_box(UI.moldura(Color.WHITE,2),Rect2(p-Vector2(3,10),Vector2(60,16)))
		draw_string(UI.fonte(),p,texto,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("ead8aa"))
	for ator in [fase.lucas,fase.otto]:
		if ator.altura_nivel==1 and not ator.pulando and ator.position.distance_to(Vector2(1040,240))<55:
			var t: String="F + DIREÇÃO" if ator==fase.lucas else "P + DIREÇÃO"
			draw_string(UI.fonte(),Vector2(1016,182),t,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("e4d3a3"))
