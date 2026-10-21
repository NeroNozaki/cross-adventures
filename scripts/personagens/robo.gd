extends "res://scripts/personagens/heroi.gd"

const PROJETIL: PackedScene = preload("res://cenas/combate/projetil.tscn")
@export var tempo_carga_total: float = 0.85
@export var dano_carregado: int = 38
var carregando: bool = false
var tempo_carga: float = 0.0
@onready var mira: Node2D = $Mira360
signal disparou(projetil: Node2D)

func _physics_process(delta: float) -> void:
	var movimento: Vector2 = Vector2.ZERO
	if esta_morto or not controlado:
		cancelar_carga()
		mira.hide()
		mover(movimento, delta)
		return
	mira.show()
	mira.atualizar(get_global_mouse_position(), tempo_carga / tempo_carga_total if carregando else 0.0)
	olhar_para(mira.direcao)
	movimento = Input.get_vector("robo_esquerda", "robo_direita", "robo_cima", "robo_baixo")
	if Input.is_action_just_pressed("robo_atacar"):
		iniciar_carga()
	if carregando:
		tempo_carga = minf(tempo_carga + delta, tempo_carga_total)
	if Input.is_action_just_released("robo_atacar"):
		liberar_carga()
	mover(movimento, delta)

func iniciar_carga() -> bool:
	if esta_morto or not controlado or not recarga.is_stopped() or tempo_dano > 0.0 or carregando:
		return false
	carregando = true
	tempo_carga = 0.0
	audio.tocar(&"carga")
	return true

func cancelar_carga() -> void:
	carregando = false
	tempo_carga = 0.0

func liberar_carga() -> Node2D:
	if not carregando:
		return null
	var proporcao: float = tempo_carga / tempo_carga_total
	cancelar_carga()
	return disparar(proporcao >= 0.999)

func iniciar_ataque() -> bool:
	# Atalho mantido para testes e integracoes que solicitam um tiro simples.
	return disparar(false) != null

func disparar(carregado: bool = false) -> Node2D:
	if esta_morto or not controlado or not recarga.is_stopped() or tempo_dano > 0.0:
		return null
	var tiro: Node2D = PROJETIL.instantiate()
	tiro.emissor = self
	tiro.direcao = mira.direcao
	tiro.carregado = carregado
	tiro.dano = dano_carregado if carregado else dano_ataque
	tiro.raio = 9.0 if carregado else 4.0
	tiro.velocidade = 270.0 if carregado else 340.0
	var sons: Array[AudioStream] = audio.perfil.ricochete
	if not sons.is_empty():
		tiro.som_ricochete = sons.pick_random()
	var origem: Vector2 = _origem_segura(tiro.raio)
	if not origem.is_finite():
		tiro.free()
		return null
	var destino: Node = get_tree().current_scene
	if destino == null:
		destino = get_parent()
	destino.add_child(tiro)
	tiro.global_position = origem
	recarga.start(0.32 if not carregado else 0.65)
	atacando = true
	tempo_ataque = 0.16
	_reproduzir("attack")
	audio.tocar(&"ataque")
	if carregado:
		audio.acoes_player.pitch_scale *= 0.8
	disparou.emit(tiro)
	return tiro

func _origem_segura(raio: float) -> Vector2:
	# Margem adicional evita iniciar tangente ou dentro de uma parede.
	var forma: CircleShape2D = CircleShape2D.new()
	forma.radius = raio + 0.7
	var consulta: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.collision_mask = 1
	consulta.collide_with_areas = false
	var espaco: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var candidatos: Array[Vector2] = [global_position + Vector2(0, -15), global_position]
	for dir in [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2(1, 1).normalized(), Vector2(-1, 1).normalized()]:
		candidatos.append(global_position + dir * (raio + 2.0))
	for ponto in candidatos:
		consulta.transform = Transform2D(0.0, ponto)
		if not espaco.intersect_shape(consulta, 1).is_empty():
			continue
		var linha: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, ponto, 1)
		if espaco.intersect_ray(linha).is_empty():
			return ponto
	return Vector2.INF

func receber_dano(valor: int, origem: Vector2) -> void:
	var antes: int = vida_atual
	super.receber_dano(valor, origem)
	if vida_atual < antes:
		cancelar_carga()

func _morrer() -> void:
	cancelar_carga()
	mira.hide()
	super._morrer()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancelar_carga()
