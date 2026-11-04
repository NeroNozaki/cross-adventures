extends Heroi

const PROJETIL: PackedScene = preload("res://cenas/combate/projetil.tscn")
@export_category("Carga")
@export var tempo_carga_total: float = 0.85
@export var dano_carregado: int = 38
@export_category("Dash")
@export var dash_speed: float = 480.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.65
var elemento: String = "normal"
var carregando: bool = false
var tempo_carga: float = 0.0
var dashing: bool = false
var dash_remaining: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_cooldown_remaining: float = 0.0
@onready var mira: Node2D = $Mira360
signal disparou(projetil: Node2D)
signal dashed

func pode_mover_atacando() -> bool:
	return true


func _pode_registrar_piso_seguro() -> bool:
	return not dashing

func _physics_process(delta: float) -> void:
	var movimento: Vector2 = Vector2.ZERO
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	if esta_morto or not controlado:
		cancelar_dash()
		cancelar_carga()
		mira.hide()
		mover(movimento, delta)
		return
	if caindo:
		cancelar_carga()
		mira.hide()
		mover(movimento, delta)
		return
	if esta_empurrado():
		cancelar_carga()
		mira.hide()
		mover(movimento, delta)
		return
	mira.show()
	mira.atualizar(get_global_mouse_position(), tempo_carga / tempo_carga_total if carregando else 0.0)
	olhar_para(mira.direcao)
	movimento = Input.get_vector("robo_esquerda", "robo_direita", "robo_cima", "robo_baixo")
	if dashing:
		_process_dash(delta)
		return
	if Input.is_action_just_pressed("otto_dash") and iniciar_dash(movimento):
		_process_dash(delta)
		return
	if Input.is_action_just_pressed("robo_atacar"):
		iniciar_carga()
	if carregando:
		tempo_carga = minf(tempo_carga + delta, tempo_carga_total)
	if Input.is_action_just_released("robo_atacar"):
		liberar_carga()
	mover(movimento, delta)

func iniciar_dash(direcao: Vector2) -> bool:
	if esta_morto or caindo or pulando or not controlado or dashing or dash_cooldown_remaining > 0.0 or tempo_dano > 0.0 or esta_empurrado():
		return false
	var rumo: Vector2 = direcao.normalized()
	if rumo.is_zero_approx():
		rumo = mira.direcao.normalized()
	if rumo.is_zero_approx():
		rumo = frente
	dashing = true
	dash_remaining = dash_duration
	dash_direction = rumo
	dash_cooldown_remaining = dash_cooldown
	cancelar_carga()
	definir_colisao_buraco(false)
	dashed.emit()
	return true

func _process_dash(delta: float) -> void:
	if not dashing:
		return
	dash_remaining -= delta
	mover(dash_direction, delta, dash_speed / maxf(velocidade, 0.001))
	if dash_remaining <= 0.0:
		finalizar_dash()

func finalizar_dash() -> void:
	if not dashing:
		return
	dashing = false
	dash_remaining = 0.0
	if esta_sobre_buraco():
		cair_no_buraco()
	else:
		definir_colisao_buraco(true)

func cancelar_dash() -> void:
	dashing = false
	dash_remaining = 0.0
	if not caindo and not esta_morto:
		definir_colisao_buraco(true)

func iniciar_carga() -> bool:
	if esta_morto or caindo or dashing or pulando or not controlado or not recarga.is_stopped() or tempo_dano > 0.0 or carregando or esta_empurrado():
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
	if esta_morto or caindo or dashing or pulando or not controlado or not recarga.is_stopped() or tempo_dano > 0.0 or esta_empurrado():
		return null
	var tiro: Node2D = PROJETIL.instantiate()
	tiro.emissor = self
	tiro.altura_nivel = altura_nivel
	tiro.elemento = elemento
	tiro.direcao = mira.direcao
	tiro.carregado = carregado
	tiro.dano = dano_carregado if carregado else dano_ataque
	tiro.raio = 9.0 if carregado else 4.0
	tiro.velocidade = tiro.VELOCIDADE_CARREGADA if carregado else tiro.VELOCIDADE_SIMPLES
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
		cancelar_dash()

func _morrer() -> void:
	cancelar_carga()
	cancelar_dash()
	mira.hide()
	super._morrer()

func respawn(restaurar_vida: bool = false, usar_ultimo_piso_seguro: bool = false) -> void:
	dashing = false
	dash_remaining = 0.0
	dash_cooldown_remaining = 0.0
	super.respawn(restaurar_vida, usar_ultimo_piso_seguro)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancelar_carga()
