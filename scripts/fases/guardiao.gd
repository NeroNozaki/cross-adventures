extends "res://scripts/personagens/cavaleiro.gd"
var protegido: bool = true
var pulso_t: float = 4.0
var aviso_t: float = 0.0
func _physics_process(delta: float) -> void:
	if esta_morto:
		return
	if protegido:
		mover(Vector2.ZERO, delta)
	else:
		super._physics_process(delta)
		pulso_t -= delta
		if pulso_t <= 0.0:
			pulso_t = 4.3
			aviso_t = 0.85
		if aviso_t > 0.0:
			aviso_t -= delta
			if aviso_t <= 0.0:
				for heroi in get_tree().get_nodes_in_group("herois"):
					if heroi.altura_nivel == altura_nivel and not heroi.pulando and global_position.distance_to(heroi.global_position) < 88:
						heroi.receber_dano(14, global_position)
	queue_redraw()

func receber_dano(valor: int, origem: Vector2) -> void:
	if not protegido:
		super.receber_dano(valor, origem)

func _morrer() -> void:
	super._morrer()
	queue_redraw()

func _draw() -> void:
	if esta_morto:
		return
	draw_set_transform(Vector2(0, -16 * altura_nivel))
	if protegido:
		draw_arc(Vector2(0, -13), 30, 0, TAU, 40, Color(0.5, 0.85, 1, 0.7), 2)
	if aviso_t > 0:
		draw_circle(Vector2.ZERO, 88, Color(1, 0.55, 0.25, 0.12))
		draw_arc(Vector2.ZERO, 88, 0, TAU, 40, Color(1, 0.65, 0.3, 0.9), 2)

	draw_set_transform(Vector2.ZERO)
