extends Node2D
## Efeitos desenhados no Godot: arco direcional, escudo erguido e faiscas de bloqueio.

var tempo_golpe: float = 0.0
var variante_golpe: int = 1
var duracao_golpe: float = 0.5
var frente_golpe: Vector2 = Vector2.DOWN
var cor_golpe: Color = Color("ffe5a0")
var defendendo: bool = false
var frente_escudo: Vector2 = Vector2.DOWN
var impacto: float = 0.0

func mostrar_golpe(frente: Vector2, duracao: float, cor: Color) -> void:
	frente_golpe = frente
	duracao_golpe = maxf(duracao, 0.1)
	tempo_golpe = duracao_golpe
	cor_golpe = cor
	queue_redraw()

func atualizar_escudo(ativo: bool, frente: Vector2) -> void:
	defendendo = ativo
	frente_escudo = frente
	queue_redraw()

func impacto_escudo() -> void:
	impacto = 0.28
	queue_redraw()

func parar() -> void:
	tempo_golpe = 0.0
	defendendo = false
	queue_redraw()

func _process(delta: float) -> void:
	tempo_golpe = maxf(0.0, tempo_golpe - delta)
	impacto = maxf(0.0, impacto - delta)
	queue_redraw()

func _draw() -> void:
	if tempo_golpe > 0.0:
		var p: float = 1.0 - tempo_golpe / duracao_golpe
		# O arco permanece inteiramente no hemisferio da direcao de ataque.
		var centro: float = frente_golpe.angle()
		var varredura: float = lerpf(0.95, -0.95, p) if variante_golpe == 2 else lerpf(-0.95, 0.95, p)
		var alfa: float = sin(p * PI)
		var cor: Color = Color(cor_golpe, alfa * 0.85)
		if variante_golpe == 3:
			var fim: Vector2 = frente_golpe * (18.0 + sin(p * PI) * 19.0)
			var lado: Vector2 = frente_golpe.orthogonal() * 4.0
			draw_colored_polygon(PackedVector2Array([frente_golpe * 10.0 + lado, fim, frente_golpe * 10.0 - lado]), Color(1, 0.72, 0.3, alfa))
			draw_line(frente_golpe * 9.0, fim, Color(1, 1, 0.8, alfa), 2.0, true)
		else:
			draw_arc(Vector2.ZERO, 26.0, centro + varredura - 0.55, centro + varredura + 0.25, 12, cor, 3.5, true)
			draw_arc(Vector2.ZERO, 31.0, centro + varredura - 0.35, centro + varredura + 0.2, 10, Color(1, 1, 0.95, alfa), 1.5, true)
	if defendendo or impacto > 0.0:
		var angulo: float = frente_escudo.angle()
		var intensidade: float = impacto / 0.28
		draw_arc(Vector2.ZERO, 23.0 + intensidade * 3.0, angulo - 0.85, angulo + 0.85, 18, Color(0.35, 0.8, 1, 0.65 + intensidade * 0.35), 2.0 + intensidade, true)
		# Escudo visivel na frente do personagem, seguindo a direcao defendida.
		var centro_escudo: Vector2 = frente_escudo * 17.0
		var lateral: Vector2 = frente_escudo.orthogonal()
		var pontos: PackedVector2Array = PackedVector2Array([
			centro_escudo - lateral * 6.0 - frente_escudo * 4.0,
			centro_escudo + lateral * 6.0 - frente_escudo * 4.0,
			centro_escudo + lateral * 5.0 + frente_escudo * 3.0,
			centro_escudo + frente_escudo * 7.0,
			centro_escudo - lateral * 5.0 + frente_escudo * 3.0
		])
		draw_colored_polygon(pontos, Color("45647b").lightened(intensidade * 0.45))
		pontos.append(pontos[0])
		draw_polyline(pontos, Color("c4eaff"), 1.5, true)
		draw_line(centro_escudo - lateral * 3.0, centro_escudo + lateral * 3.0, Color("d9f5ff"), 1.5)
	if impacto > 0.0:
		var ponto: Vector2 = frente_escudo * 26.0
		for i in range(7):
			var dir: Vector2 = frente_escudo.rotated(-1.2 + float(i) * 0.4)
			var distancia: float = 5.0 + (1.0 - impacto / 0.28) * 15.0
			draw_line(ponto + dir * distancia, ponto + dir * (distancia + 4.0), Color(0.9, 0.97, 1.0, impacto / 0.28), 1.5, true)
