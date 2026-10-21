extends Node2D
## Pecas da propria armadura, sem corpo. Permanecem no local da morte ate reiniciar.

var caiu: bool = false
var poeira: float = 0.0

func cair() -> void:
	if caiu:
		return
	caiu = true
	show()
	poeira = 0.45
	var t: Tween = create_tween().set_parallel(true)
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property($Elmo, "position", Vector2(-13, -3), 0.38)
	t.tween_property($Elmo, "rotation", -0.55, 0.38)
	t.tween_property($Peitoral, "position", Vector2(3, 1), 0.32)
	t.tween_property($Peitoral, "rotation", 1.35, 0.32)
	t.tween_property($Botas, "position", Vector2(14, 7), 0.42)
	t.tween_property($Botas, "rotation", 0.5, 0.42)

func _process(delta: float) -> void:
	if poeira > 0.0:
		poeira = maxf(0.0, poeira - delta)
		queue_redraw()

func _draw() -> void:
	if not caiu:
		return
	draw_set_transform(Vector2(0, 5), 0, Vector2(1.8, 0.45))
	draw_circle(Vector2.ZERO, 11.0, Color(0.04, 0.06, 0.07, 0.4))
	draw_set_transform(Vector2.ZERO)
	if poeira > 0.0:
		draw_arc(Vector2(0, 5), 10.0 + (1.0 - poeira / 0.45) * 15.0, 0, TAU, 24, Color(0.65, 0.65, 0.5, poeira * 0.7), 2.0)
