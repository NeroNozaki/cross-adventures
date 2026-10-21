extends Node2D
## Coordenadas do mundo: funciona com redimensionamento da janela e Camera2D.

@export var comprimento_maximo: float = 520.0
var direcao: Vector2 = Vector2.RIGHT
var comprimento: float = 120.0
var carga: float = 0.0

func atualizar(alvo_global: Vector2, progresso: float) -> void:
	var ate_alvo: Vector2 = alvo_global - global_position
	if ate_alvo.length_squared() > 0.01:
		direcao = ate_alvo.normalized()
	comprimento = clampf(ate_alvo.length(), 22.0, comprimento_maximo)
	carga = clampf(progresso, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var cor: Color = Color("ffcd65") if carga >= 1.0 else Color("73e9ff")
	draw_dashed_line(direcao * 18.0, direcao * comprimento, Color(cor, 0.55), 1.0, 5.0)
	var ponta: Vector2 = direcao * comprimento
	draw_circle(ponta, 4.0, Color(cor, 0.9), false, 1.0, true)
	draw_line(ponta + Vector2(-7, 0), ponta + Vector2(7, 0), cor, 1.0)
	draw_line(ponta + Vector2(0, -7), ponta + Vector2(0, 7), cor, 1.0)
	# Pequeno emissor gira livremente; o corpo continua usando seus sprites em 4 direcoes.
	var lado: Vector2 = direcao.orthogonal() * 3.0
	draw_colored_polygon(PackedVector2Array([direcao * 11.0 + lado, direcao * 21.0 + lado, direcao * 21.0 - lado, direcao * 11.0 - lado]), Color("527c8e"))
	draw_circle(direcao * 21.0, 2.2 + carga * 2.8, cor)
	if carga > 0.0:
		draw_arc(Vector2.ZERO, 21.0, -PI / 2.0, -PI / 2.0 + TAU * carga, 36, cor, 2.0, true)
