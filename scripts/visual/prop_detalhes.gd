extends Node2D
var objeto: Node2D
var tempo: float=0.0
func _ready() -> void:
	objeto=get_parent()
	tempo=float(posmod(hash(str(objeto.name)),19))
func _process(delta: float) -> void:
	tempo+=delta
	visible=not objeto.esta_morto
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(objeto) or objeto.esta_morto: return
	var off: Vector2=Vector2(0,-16*objeto.altura_nivel)
	if objeto.tipo()=="barril":
		# Aros, pequenas marcas na madeira e brilho curto no metal do atlas nativo.
		for p: Vector2 in [Vector2(-8,-24),Vector2(6,-22),Vector2(-10,-8)]:
			draw_rect(Rect2(off+p,Vector2(2,2)),Color("a5a1a1"))
		draw_rect(Rect2(off+Vector2(-4,-18),Vector2(2,8)),Color(0.2,0.15,0.18,0.35))
		if fmod(tempo,7.0)<0.2:
			draw_rect(Rect2(off+Vector2(8,-8),Vector2(2,4)),Color("d1c7a4"))
	elif objeto.tipo()=="caixa":
		draw_rect(Rect2(off+Vector2(-10,-22),Vector2(18,2)),Color(0.76,0.62,0.4,0.5))
		for x in [-10,8]: draw_rect(Rect2(off+Vector2(x,-8),Vector2(2,2)),Color("b6a17a"))
