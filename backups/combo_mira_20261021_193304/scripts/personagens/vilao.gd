extends "res://scripts/personagens/personagem_base.gd"
## IA simples: espera, persegue o heroi mais proximo e ataca ao se aproximar.

@export_category("Inteligencia artificial")
@export var raio_deteccao: float = 180.0
@export var distancia_retorno: float = 240.0
var ponto_inicial: Vector2

func _ready() -> void:
	super._ready()
	ponto_inicial = global_position

func _physics_process(delta: float) -> void:
	var movimento: Vector2 = Vector2.ZERO
	if not esta_morto:
		var alvo: CharacterBody2D = _procurar_alvo()
		if is_instance_valid(alvo):
			var ate_alvo: Vector2 = alvo.global_position - global_position
			if not atacando:
				olhar_para(ate_alvo)
			if ate_alvo.length() <= alcance_ataque:
				iniciar_ataque()
			else:
				movimento = ate_alvo.normalized()
		elif global_position.distance_to(ponto_inicial) > 5.0:
			movimento = global_position.direction_to(ponto_inicial)
	mover(movimento, delta)

func _procurar_alvo() -> CharacterBody2D:
	var escolhido: CharacterBody2D
	var distancia_minima: float = raio_deteccao
	if global_position.distance_to(ponto_inicial) > distancia_retorno:
		return null
	for heroi in get_tree().get_nodes_in_group("herois"):
		if heroi.esta_morto:
			continue
		var distancia: float = global_position.distance_to(heroi.global_position)
		if distancia < distancia_minima:
			distancia_minima = distancia
			escolhido = heroi
	return escolhido
