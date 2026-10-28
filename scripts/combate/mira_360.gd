extends Node2D
## Coordenadas do mundo: funciona com redimensionamento da janela e Camera2D.

@export var comprimento_maximo: float = 520.0
var travada: bool = false
var trajeto: PackedVector2Array = PackedVector2Array()
var consulta: ShapeCast2D
var direcao: Vector2 = Vector2.RIGHT
var comprimento: float = 120.0
var carga: float = 0.0

func atualizar(alvo_global: Vector2, progresso: float) -> void:
	var ate_alvo: Vector2 = alvo_global - global_position
	if not travada and ate_alvo.length_squared() > 0.01:
		direcao = ate_alvo.normalized()
	comprimento = clampf(ate_alvo.length(), 22.0, comprimento_maximo)
	carga = clampf(progresso, 0.0, 1.0)
	if is_inside_tree() and get_tree().get_first_node_in_group("fase_atual") != null:
		_prever()
	else:
		trajeto = PackedVector2Array()
	queue_redraw()

func _draw() -> void:
	var cor: Color = Color("ffcd65") if carga >= 1.0 else Color("73e9ff")
	if trajeto.size() >= 2:
		for i in range(1, trajeto.size()):
			if i > 1 and not travada and carga <= 0.0:
				break
			draw_dashed_line(trajeto[i - 1], trajeto[i], Color(cor, 0.55 - float(i - 1) * 0.07), 1.0, 6.0)
			if i < trajeto.size() - 1:
				draw_circle(trajeto[i], 3, cor, false, 1.0)
	else:
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

func _prever() -> void:
	if consulta == null:
		consulta = ShapeCast2D.new()
		consulta.enabled = false
		consulta.collision_mask = 1
		consulta.collide_with_areas = false
		add_child(consulta)
	var forma: CircleShape2D = CircleShape2D.new()
	forma.radius = 9.0 if carga >= 1.0 else 4.0
	consulta.shape = forma
	consulta.clear_exceptions()
	var z: int = get_parent().altura_nivel
	var offset: Vector2 = Vector2(0, 16 * z)
	var p: Vector2 = get_parent()._origem_segura(forma.radius)
	if not p.is_finite():
		trajeto = PackedVector2Array()
		return
	var vetor: Vector2 = direcao
	var restante: float = 4000.0
	trajeto = PackedVector2Array([to_local(p - offset)])
	var contatos: int = 0
	var tentativas: int = 0
	while contatos < 4 and tentativas < 24:
		tentativas += 1
		consulta.global_position = p
		consulta.target_position = vetor * restante
		consulta.force_shapecast_update()
		if not consulta.is_colliding():
			trajeto.append(to_local(p + vetor * restante - offset))
			break
		var distancia: float = restante * consulta.get_closest_collision_safe_fraction()
		p += vetor * distancia
		restante -= distancia
		var corpo: Object = consulta.get_collider(0)
		if corpo.has_meta("altura") and int(corpo.get_meta("altura")) >= 0 and int(corpo.get_meta("altura")) != z:
			consulta.add_exception_rid(corpo.get_rid())
			continue
		trajeto.append(to_local(p - offset))
		if corpo.has_method("tipo"):
			var t: String = corpo.tipo()
			if t in ["receptor", "condutor", "agua", "bolha", "planta", "barril"] or (t in ["gelo", "barreira_gelo"] and get_parent().elemento == "fogo"):
				break
		var normal: Vector2 = consulta.get_collision_normal(0)
		if corpo.has_method("tipo") and corpo.tipo() == "espelho":
			normal = corpo.global_transform.y.normalized()
			if vetor.dot(normal)>0: normal = -normal
		if normal.length_squared() < 0.01:
			break
		contatos += 1
		vetor = vetor.bounce(normal).normalized()
		p += normal * 0.8
	consulta.position = Vector2.ZERO
