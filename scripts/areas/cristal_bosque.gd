extends Node2D
signal aceso
var livre := false
var ativo := false
var animacao: Tween

func _ready() -> void:
	$animation.position.y = -4
	$animation.modulate.a = 0
	$animation.scale = Vector2(2,2)
	$Area2D/CollisionShape2D.shape = $Area2D/CollisionShape2D.shape.duplicate()
	$Area2D/CollisionShape2D.shape.radius = 22

func receber_projetil(_tiro: Node) -> String:
	if livre and not ativo:
		ativo = true
		aceso.emit()
		atualizar_visual()
	return "consumir"

func atualizar_visual() -> void:
	if animacao:
		animacao.kill()
	$animation.play("gold" if ativo else ("blue" if livre else "red"))
	animacao = create_tween().set_parallel(true)
	animacao.tween_property($animation,"position:y",-26 if livre or ativo else -4,0.24)
	animacao.tween_property($animation,"modulate:a",1.0 if livre or ativo else 0.0,0.24)
	queue_redraw()

func _draw() -> void:
	if livre and not ativo:
		for x in [-20,20]:
			draw_line(Vector2(x,-36),Vector2(x,-18),Color("#fff1b0"),2)
			draw_line(Vector2(x,-36),Vector2(x-signf(x)*6,-36),Color("#fff1b0"),2)
