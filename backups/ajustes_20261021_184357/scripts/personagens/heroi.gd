extends "res://scripts/personagens/personagem_base.gd"
## O heroi selecionado recebe comandos; o companheiro acompanha e luta perto dele.

@export var controlado: bool = false
@export var distancia_companheiro: float = 58.0
var lider: CharacterBody2D

func _physics_process(delta: float) -> void:
	var movimento: Vector2 = Vector2.ZERO
	if not esta_morto:
		if controlado:
			movimento = Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
			if movimento.length_squared() > 0.01 and not atacando:
				olhar_para(movimento)
			if Input.is_action_just_pressed("atacar"):
				iniciar_ataque()
		else:
			movimento = _seguir_lider()
	mover(movimento, delta)

func _seguir_lider() -> Vector2:
	if not is_instance_valid(lider) or lider.esta_morto:
		return Vector2.ZERO
	var inimigo: CharacterBody2D
	var menor_distancia: float = alcance_ataque + 14.0
	for candidato in get_tree().get_nodes_in_group("viloes"):
		if candidato.esta_morto:
			continue
		var distancia: float = global_position.distance_to(candidato.global_position)
		if distancia < menor_distancia:
			menor_distancia = distancia
			inimigo = candidato
	if is_instance_valid(inimigo):
		if not atacando:
			olhar_para(inimigo.global_position - global_position)
		iniciar_ataque()
		return Vector2.ZERO
	var ate_lider: Vector2 = lider.global_position - global_position
	if ate_lider.length() > distancia_companheiro:
		return ate_lider.normalized()
	return Vector2.ZERO
