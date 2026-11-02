@tool
extends Node2D
@export var indice: int=0
var tempo: float=0
func _process(delta: float) -> void:
	tempo+=delta
	queue_redraw()
func _draw() -> void:
	if Engine.is_editor_hint(): return
	var fase: Node2D=get_parent()
	if fase.dados.is_empty(): return
	if indice==3:
		var c: Vector2=Vector2(624,560)
		draw_rect(Rect2(c-Vector2(128,128),Vector2(256,256)),Color(0.25,0.12,0.19,0.14))
		for raio in [112,98]: draw_arc(c,raio,0,TAU,64,Color(0.7,0.5,0.24,0.42),1)
		for i in range(12):
			var d: Vector2=Vector2.RIGHT.rotated(float(i)*TAU/12)
			draw_line(c+d*100,c+d*110,Color(0.7,0.5,0.24,0.5),2)
	for i in range(36):
		var p: Vector2=Vector2(fmod(i*131+sin(tempo*0.2+i)*8,fase.dados.largura*32),fmod(i*173-tempo*4+3000,fase.dados.altura*32))
		draw_rect(Rect2(p,Vector2.ONE),Color(0.9,0.8,0.6,0.14))
