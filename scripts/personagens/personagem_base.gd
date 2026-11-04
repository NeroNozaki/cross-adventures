extends CharacterBody2D
class_name PersonagemBase
## Base de combate compartilhada. O ponto (0, 0) fica nos pes do personagem.

signal vida_alterada(atual: int, maxima: int)
signal morreu(personagem: CharacterBody2D)
signal bloqueou
signal caiu_no_buraco(personagem: CharacterBody2D)
signal renasceu(personagem: CharacterBody2D)

@export_category("Atributos RPG")
@export var nome_personagem: String = "Personagem"
@export_enum("Heroi", "Vilao") var equipe: int = 0
@export var vida_maxima: int = 100
@export var velocidade: float = 95.0
@export var orientar_pelo_movimento: bool = true
@export var dano_ataque: int = 15
@export var defesa: int = 2
@export_category("Combate")
@export var alcance_ataque: float = 29.0
@export var intervalo_ataque: float = 0.7
@export var preparo_ataque: float = 0.18
@export var duracao_ataque: float = 0.5
@export var tempo_invulneravel: float = 0.4
@export_category("Escudo")
@export_range(0.1, 1.0) var velocidade_defendendo: float = 0.45
@export_category("Visual")
@export var possui_morte_animada: bool = true
@export_category("Queda e renascimento")
@export var dano_queda: int = 20
@export var duracao_queda: float = 0.45
@export var tempo_renascimento_morte: float = 1.0

const IMPULSO_DECAY: float = 420.0

@export var altura_nivel: int = 0
var pulando: bool = false
var altura_salto: float = 0.0
var tempo_salto: float = 0.0
var salto_origem: Vector2
var salto_destino: Vector2
var vida_atual: int = 0
var esta_morto: bool = false
var atacando: bool = false
var defendendo: bool = false
var direcao: String = "down"
var frente: Vector2 = Vector2.DOWN
var impulso: Vector2 = Vector2.ZERO
var tempo_empurrao: float = 0.0
var ultima_posicao_segura: Vector2 = Vector2.ZERO
var ponto_seguro_inicial: Vector2 = Vector2.ZERO
var tempo_ataque: float = 0.0
var tempo_dano: float = 0.0
var velocidade_controle: Vector2 = Vector2.ZERO
var visual_offset: Vector2
var caindo: bool = false
var posicao_renascimento: Vector2
var camada_colisao_padrao: int
var mascara_colisao_padrao: int
var camada_area_dano_padrao: int
var posicao_visual_padrao: Vector2

@onready var animacao: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var barra_vida: ProgressBar = $BarraVida
@onready var nome_label: Label = $Nome
@onready var recarga: Timer = $RecargaAtaque
@onready var preparo: Timer = $PreparoAtaque
@onready var invulnerabilidade: Timer = $Invulnerabilidade
@onready var area_ataque: Area2D = $PivoAtaque/AreaAtaque
@onready var area_dano: Area2D = $AreaDano
@onready var efeitos: Node2D = $EfeitosCombate
@onready var audio: Node2D = $AudioPersonagem

func _ready() -> void:
	vida_atual = vida_maxima
	# Combate e recarga usam o mesmo relogio da simulacao fisica.
	for timer in [recarga, preparo, invulnerabilidade]:
		timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	visual_offset = animacao.offset
	posicao_visual_padrao = animacao.position
	camada_colisao_padrao = collision_layer
	collision_mask = collision_mask | (1 << (PhysicsLayers.HOLES - 1))
	mascara_colisao_padrao = collision_mask
	posicao_renascimento = global_position
	ultima_posicao_segura = global_position
	ponto_seguro_inicial = global_position
	barra_vida.max_value = vida_maxima
	barra_vida.value = vida_atual
	nome_label.text = nome_personagem
	add_to_group("combatentes")
	add_to_group("herois" if equipe == 0 else "viloes")
	area_dano.collision_layer = 8 if equipe == 0 else 16
	camada_area_dano_padrao = area_dano.collision_layer
	area_ataque.collision_mask = 16 if equipe == 0 else 8
	preparo.timeout.connect(_aplicar_ataque)
	vida_alterada.emit(vida_atual, vida_maxima)
	_reproduzir("idle")

func atualizar_estado(delta: float) -> void:
	tempo_dano = maxf(0.0, tempo_dano - delta)
	tempo_empurrao = maxf(0.0, tempo_empurrao - delta)
	impulso = impulso.move_toward(Vector2.ZERO, IMPULSO_DECAY * delta)
	if atacando:
		tempo_ataque -= delta
		if tempo_ataque <= 0.0:
			atacando = false
	if not esta_morto and not caindo:
		if invulnerabilidade.is_stopped():
			animacao.modulate = Color.WHITE
		else:
			animacao.modulate = Color(1.0, 0.5, 0.5, 0.75)

func pode_mover_atacando() -> bool:
	return false

func mover(vetor: Vector2, delta: float, multiplicador: float = 1.0) -> void:
	var empurrado: bool = tempo_empurrao > 0.0
	atualizar_estado(delta)
	if esta_morto or caindo:
		velocity = Vector2.ZERO
		return
	if orientar_pelo_movimento and not empurrado and not atacando and not defendendo and vetor.length_squared() > 0.01:
		olhar_para(vetor)
	var fator: float = velocidade_defendendo if defendendo else 1.0
	# Sem aceleracao de entrada: andar, parar e inverter respondem no mesmo quadro.
	var deseja: Vector2 = vetor.limit_length() * velocidade * fator * maxf(multiplicador, 0.0)
	if atacando and not pode_mover_atacando():
		deseja = Vector2.ZERO
	if empurrado:
		deseja = Vector2.ZERO
	velocidade_controle = deseja
	velocity = deseja + impulso
	efeitos.atualizar_escudo(defendendo, frente)
	var posicao_anterior: Vector2 = global_position
	var fase: Node = get_tree().get_first_node_in_group("fase_atual")
	if fase != null:
		fase.mover_personagem(self, delta)
	else:
		move_and_slide()
	if empurrado and esta_sobre_buraco():
		cair_no_buraco()
		return
	if not empurrado and not pulando and vetor.length_squared() > 0.01 and _pode_registrar_piso_seguro() and not esta_sobre_buraco() and not esta_sobre_terreno_instavel():
		ultima_posicao_segura = global_position
	audio.registrar_movimento(global_position.distance_to(posicao_anterior), not empurrado and vetor.length_squared() > 0.01 and not pulando and (not atacando or pode_mover_atacando()))
	if defendendo:
		_reproduzir("walk" if global_position.distance_squared_to(posicao_anterior) > 0.0001 and not pulando else "idle")
	elif empurrado or (tempo_dano > 0.0 and not atacando):
		_reproduzir("hurt")
	elif not atacando:
		_reproduzir("walk" if global_position.distance_squared_to(posicao_anterior) > 0.0001 and not pulando else "idle")
	if empurrado and tempo_empurrao <= 0.0:
		_finalizar_empurrao()


func _pode_registrar_piso_seguro() -> bool:
	return true


func esta_empurrado() -> bool:
	return tempo_empurrao > 0.0


func definir_ultima_posicao_segura(ponto: Vector2) -> void:
	if ponto.is_finite():
		ultima_posicao_segura = ponto


func definir_ponto_seguro_inicial(ponto: Vector2) -> void:
	if ponto.is_finite():
		ponto_seguro_inicial = ponto


func _finalizar_empurrao() -> void:
	if esta_morto or caindo:
		return
	if esta_sobre_buraco():
		cair_no_buraco()
	else:
		definir_colisao_buraco(true)

func olhar_para(vetor: Vector2) -> void:
	if vetor.length_squared() < 0.001:
		return
	if absf(vetor.x) > absf(vetor.y):
		direcao = "right" if vetor.x > 0.0 else "left"
		frente = Vector2.RIGHT if vetor.x > 0.0 else Vector2.LEFT
	else:
		direcao = "down" if vetor.y > 0.0 else "up"
		frente = Vector2.DOWN if vetor.y > 0.0 else Vector2.UP

func definir_defesa(_ativa: bool) -> void:
	pass

func iniciar_ataque() -> bool:
	if esta_morto or caindo or pulando or atacando or defendendo or tempo_dano > 0.0 or esta_empurrado() or not recarga.is_stopped():
		return false
	atacando = true
	tempo_ataque = duracao_ataque
	$PivoAtaque.position = frente * alcance_ataque * 0.65 + Vector2(0, -10)
	$PivoAtaque.rotation = frente.angle()
	recarga.start(intervalo_ataque)
	preparo.start(preparo_ataque)
	_reproduzir("attack")
	$PivoAtaque/EfeitoGolpe.visible = false
	var cor: Color = Color("ffe5a0") if equipe == 0 else Color("ff8a6a")
	efeitos.mostrar_golpe(frente, duracao_ataque, cor)
	audio.tocar(&"ataque")
	return true

func _esconder_golpe() -> void:
	$PivoAtaque/EfeitoGolpe.visible = false

func obter_dano_ataque() -> int:
	return dano_ataque

func _tem_linha_de_visao(alvo: Vector2, ignorar: CollisionObject2D = null) -> bool:
	var consulta: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, alvo, 1)
	if ignorar != null:
		consulta.exclude = [ignorar.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()

func _aplicar_ataque() -> void:
	if esta_morto or not atacando:
		return
	# A area fica ativa para que a fisica atualize sobreposicoes antes do impacto.
	var atingidos: Array[Node] = []
	var confirmou_acerto: bool = false
	for area in area_ataque.get_overlapping_areas():
		var alvo: Node = area.get_parent()
		if alvo == self or atingidos.has(alvo) or not alvo.has_method("receber_dano"):
			continue
		if alvo.equipe == equipe or int(alvo.get("altura_nivel")) != altura_nivel or alvo.get("pulando") == true:
			continue
		var ate_alvo: Vector2 = alvo.global_position - global_position
		if ate_alvo.length_squared() > 0.01 and ate_alvo.normalized().dot(frente) < 0.15:
			continue
		if not _tem_linha_de_visao(alvo.global_position, alvo as CollisionObject2D):
			continue
		atingidos.append(alvo)
		var vida_anterior: int = alvo.vida_atual
		alvo.receber_dano(obter_dano_ataque(), global_position)
		confirmou_acerto = confirmou_acerto or alvo.vida_atual < vida_anterior
	if confirmou_acerto:
		audio.tocar(&"acerto")

func receber_dano(valor: int, origem: Vector2) -> void:
	if esta_morto or caindo or not invulnerabilidade.is_stopped():
		return
	if _blocks_hit_from(origem):
		_block_hit(origem, true)
		return
	definir_defesa(false)
	var dano_final: int = maxi(1, valor - defesa)
	vida_atual = maxi(0, vida_atual - dano_final)
	barra_vida.value = vida_atual
	vida_alterada.emit(vida_atual, vida_maxima)
	if vida_atual == 0:
		_morrer()
		return
	atacando = false
	tempo_ataque = 0.0
	preparo.stop()
	efeitos.parar()
	audio.tocar(&"dano")
	tempo_dano = 0.24
	invulnerabilidade.start(tempo_invulneravel)
	impulso = (global_position - origem).normalized() * 65.0
	if not atacando:
		_reproduzir("hurt")


func receive_projectile_hit(amount: int, origin: Vector2, hit_direction: Vector2, force: float) -> bool:
	if _blocks_hit_from(origin):
		_block_hit(origin, false)
		return true
	var previous_health: int = vida_atual
	receber_dano(amount, origin)
	if vida_atual < previous_health and not esta_morto:
		var push_direction: Vector2 = hit_direction.normalized()
		if push_direction.length_squared() < 0.001:
			push_direction = (global_position - origin).normalized()
		impulso += push_direction * force
		tempo_empurrao = maxf(tempo_empurrao, impulso.length() / IMPULSO_DECAY)
		definir_colisao_buraco(false)
	return false


func _blocks_hit_from(origin: Vector2) -> bool:
	if not defendendo:
		return false
	var to_origin: Vector2 = origin - global_position
	return to_origin.length_squared() > 0.01 and to_origin.normalized().dot(frente) >= 0.45


func _block_hit(origin: Vector2, apply_recoil: bool) -> void:
	efeitos.impacto_escudo()
	audio.tocar(&"bloqueio")
	if apply_recoil:
		var to_origin: Vector2 = origin - global_position
		if to_origin.length_squared() > 0.01:
			impulso = -to_origin.normalized() * 12.0
	bloqueou.emit()

func _morrer() -> void:
	esta_morto = true
	caindo = false
	atacando = false
	defendendo = false
	tempo_empurrao = 0.0
	efeitos.parar()
	audio.finalizar()
	velocity = Vector2.ZERO
	preparo.stop()
	$PivoAtaque/EfeitoGolpe.visible = false
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	area_dano.set_deferred("collision_layer", 0)
	barra_vida.hide()
	nome_label.modulate = Color(0.7, 0.7, 0.7)
	_reproduzir("death")
	if not possui_morte_animada:
		var fade: Tween = create_tween()
		fade.tween_property(animacao, "modulate:a", 0.25, 0.8)
	morreu.emit(self)
	if equipe == 0:
		_agendar_renascimento_morte()


func _agendar_renascimento_morte() -> void:
	await get_tree().create_timer(tempo_renascimento_morte).timeout
	if is_inside_tree() and esta_morto:
		respawn(true)


func definir_ponto_renascimento(ponto: Vector2) -> void:
	if ponto.is_finite():
		posicao_renascimento = ponto

func obter_ponto_renascimento() -> Vector2:
	return posicao_renascimento

func definir_colisao_buraco(ativa: bool) -> void:
	set_collision_mask_value(PhysicsLayers.HOLES, ativa)

func esta_sobre_terreno_instavel(ponto: Vector2 = Vector2.INF) -> bool:
	var alvo: Vector2 = global_position if not ponto.is_finite() else ponto
	if not alvo.is_finite():
		return false
	var colisao: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colisao == null or colisao.shape == null:
		return false
	var consulta: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	consulta.shape = colisao.shape
	consulta.transform = colisao.global_transform
	consulta.transform.origin = alvo + (colisao.global_position - global_position)
	consulta.collision_mask = 1 << (PhysicsLayers.UNSTABLE_GROUND - 1)
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = true
	consulta.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()


func _resolver_ponto_renascimento(preferido: Vector2) -> Vector2:
	if not esta_sobre_terreno_instavel(preferido):
		return preferido
	if not esta_sobre_terreno_instavel(ultima_posicao_segura):
		return ultima_posicao_segura
	if not esta_sobre_terreno_instavel(ponto_seguro_inicial):
		return ponto_seguro_inicial
	return preferido


func esta_sobre_buraco() -> bool:
	var colisao: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colisao == null or colisao.shape == null:
		return false
	var consulta: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	consulta.shape = colisao.shape
	consulta.transform = colisao.global_transform
	consulta.collision_mask = 1 << (PhysicsLayers.HOLES - 1)
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false
	consulta.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()

func cair_no_buraco() -> void:
	if esta_morto or caindo:
		return
	caindo = true
	atacando = false
	defendendo = false
	tempo_ataque = 0.0
	tempo_empurrao = 0.0
	impulso = Vector2.ZERO
	velocidade_controle = Vector2.ZERO
	velocity = Vector2.ZERO
	preparo.stop()
	efeitos.parar()
	$PivoAtaque/EfeitoGolpe.visible = false
	_aplicar_dano_queda(dano_queda)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	area_dano.set_deferred("collision_layer", 0)
	barra_vida.hide()
	_reproduzir("hurt")
	caiu_no_buraco.emit(self)
	var queda: Tween = create_tween()
	queda.set_parallel(true)
	queda.tween_property(animacao, "position", posicao_visual_padrao + Vector2(0, 24), duracao_queda)
	queda.tween_property(animacao, "modulate:a", 0.0, duracao_queda)
	queda.chain().tween_callback(Callable(self, "_respawn_no_piso_seguro"))


func _respawn_no_piso_seguro() -> void:
	respawn(false, true)


func _aplicar_dano_queda(valor: int) -> void:
	if valor <= 0:
		return
	vida_atual = maxi(1, vida_atual - valor)
	barra_vida.value = vida_atual
	vida_alterada.emit(vida_atual, vida_maxima)
	tempo_dano = 0.24
	audio.tocar(&"dano")

func respawn(restaurar_vida: bool = false, usar_ultimo_piso_seguro: bool = false) -> void:
	if not is_inside_tree():
		return
	var estava_morto: bool = esta_morto
	caindo = false
	esta_morto = false
	atacando = false
	defendendo = false
	tempo_ataque = 0.0
	tempo_dano = 0.0
	tempo_empurrao = 0.0
	impulso = Vector2.ZERO
	velocidade_controle = Vector2.ZERO
	velocity = Vector2.ZERO
	preparo.stop()
	recarga.stop()
	invulnerabilidade.stop()
	efeitos.parar()
	$PivoAtaque/EfeitoGolpe.visible = false
	if restaurar_vida or estava_morto:
		vida_atual = vida_maxima
	else:
		vida_atual = maxi(1, vida_atual)
	barra_vida.max_value = vida_maxima
	barra_vida.value = vida_atual
	barra_vida.show()
	nome_label.modulate = Color.WHITE
	animacao.modulate = Color.WHITE
	animacao.position = posicao_visual_padrao
	if audio.has_method("reviver"):
		audio.call(&"reviver")
	var destino: Vector2 = ultima_posicao_segura if usar_ultimo_piso_seguro else posicao_renascimento
	global_position = _resolver_ponto_renascimento(destino)
	ultima_posicao_segura = global_position
	set_deferred("collision_layer", camada_colisao_padrao)
	set_deferred("collision_mask", mascara_colisao_padrao)
	area_dano.set_deferred("collision_layer", camada_area_dano_padrao)
	vida_alterada.emit(vida_atual, vida_maxima)
	_reproduzir("idle")
	renasceu.emit(self)

func _reproduzir(acao: String) -> void:
	var nome: StringName = StringName(acao + "_" + direcao)
	if not animacao.sprite_frames.has_animation(nome):
		nome = StringName("idle_" + direcao)
	animacao.play(nome)
	# O guerreiro usa uma tela maior no ataque, com os pes no mesmo ponto.
	animacao.offset = visual_offset
