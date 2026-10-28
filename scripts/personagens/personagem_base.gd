extends CharacterBody2D
## Base de combate compartilhada. O ponto (0, 0) fica nos pes do personagem.

signal vida_alterada(atual: int, maxima: int)
signal morreu(personagem: CharacterBody2D)
signal bloqueou

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
@export var pode_usar_escudo: bool = false
@export_range(0.1, 1.0) var velocidade_defendendo: float = 0.45
@export_category("Visual")
@export var possui_morte_animada: bool = true

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
var tempo_ataque: float = 0.0
var tempo_dano: float = 0.0
var velocidade_controle: Vector2 = Vector2.ZERO
var visual_offset: Vector2

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
	var respiracao: Node=Node.new()
	respiracao.name="Respiracao"
	respiracao.set_script(preload("res://scripts/visual/respiracao.gd"))
	add_child(respiracao)
	barra_vida.max_value = vida_maxima
	barra_vida.value = vida_atual
	nome_label.text = nome_personagem
	add_to_group("combatentes")
	add_to_group("herois" if equipe == 0 else "viloes")
	area_dano.collision_layer = 8 if equipe == 0 else 16
	area_ataque.collision_mask = 16 if equipe == 0 else 8
	preparo.timeout.connect(_aplicar_ataque)
	vida_alterada.emit(vida_atual, vida_maxima)
	_reproduzir("idle")

func atualizar_estado(delta: float) -> void:
	tempo_dano = maxf(0.0, tempo_dano - delta)
	impulso = impulso.move_toward(Vector2.ZERO, 420.0 * delta)
	if atacando:
		tempo_ataque -= delta
		if tempo_ataque <= 0.0:
			atacando = false
	if not esta_morto:
		if invulnerabilidade.is_stopped():
			animacao.modulate = Color.WHITE
		else:
			animacao.modulate = Color(1.0, 0.5, 0.5, 0.75)

func mover(vetor: Vector2, delta: float) -> void:
	atualizar_estado(delta)
	if esta_morto:
		velocity = Vector2.ZERO
		return
	if orientar_pelo_movimento and not atacando and vetor.length_squared() > 0.01:
		olhar_para(vetor)
	var fator: float = velocidade_defendendo if defendendo else 1.0
	# Aceleração curta e reversão suave; soltar o comando para imediatamente.
	var deseja: Vector2 = vetor.limit_length() * velocidade * fator
	if atacando and not (equipe == 0 and nome_personagem == "Otto"):
		deseja = Vector2.ZERO
	if vetor.is_zero_approx() or deseja.is_zero_approx():
		velocidade_controle = Vector2.ZERO
	else:
		velocidade_controle = velocidade_controle.move_toward(deseja, 1200.0 * delta)
	velocity = velocidade_controle + impulso if equipe == 0 else deseja + impulso
	efeitos.atualizar_escudo(defendendo, frente)
	var posicao_anterior: Vector2 = global_position
	var fase: Node = get_tree().get_first_node_in_group("fase_atual")
	if fase != null:
		fase.mover_personagem(self, delta)
	else:
		move_and_slide()
	audio.registrar_movimento(global_position.distance_to(posicao_anterior), vetor.length_squared() > 0.01 and not pulando and (not atacando or (equipe == 0 and nome_personagem == "Otto")))
	if defendendo:
		_reproduzir("idle")
	elif tempo_dano > 0.0 and not atacando:
		_reproduzir("hurt")
	elif not atacando:
		_reproduzir("walk" if global_position.distance_squared_to(posicao_anterior) > 0.0001 and not pulando else "idle")

func olhar_para(vetor: Vector2) -> void:
	if vetor.length_squared() < 0.001:
		return
	if absf(vetor.x) > absf(vetor.y):
		direcao = "right" if vetor.x > 0.0 else "left"
		frente = Vector2.RIGHT if vetor.x > 0.0 else Vector2.LEFT
	else:
		direcao = "down" if vetor.y > 0.0 else "up"
		frente = Vector2.DOWN if vetor.y > 0.0 else Vector2.UP

func definir_defesa(ativa: bool) -> void:
	var ja_defendia: bool = defendendo
	defendendo = ativa and pode_usar_escudo and not esta_morto and not pulando and not atacando and tempo_dano <= 0.0
	efeitos.atualizar_escudo(defendendo, frente)
	if defendendo and not ja_defendia:
		audio.tocar(&"defesa")

func iniciar_ataque() -> bool:
	if esta_morto or pulando or atacando or defendendo or tempo_dano > 0.0 or not recarga.is_stopped():
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
	if esta_morto or not invulnerabilidade.is_stopped():
		return
	var ate_origem: Vector2 = origem - global_position
	if defendendo and ate_origem.length_squared() > 0.01 and ate_origem.normalized().dot(frente) >= 0.45:
		efeitos.impacto_escudo()
		audio.tocar(&"bloqueio")
		impulso = -ate_origem.normalized() * 12.0
		bloqueou.emit()
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

func _morrer() -> void:
	esta_morto = true
	atacando = false
	defendendo = false
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

func _reproduzir(acao: String) -> void:
	var nome: StringName = StringName(acao + "_" + direcao)
	if not animacao.sprite_frames.has_animation(nome):
		nome = StringName("idle_" + direcao)
	animacao.play(nome)
	# O guerreiro usa uma tela maior no ataque, com os pes no mesmo ponto.
	animacao.offset = visual_offset
