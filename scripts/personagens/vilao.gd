extends "res://scripts/personagens/personagem_base.gd"
## Patrulha local lenta; perseguição e combate conservam suas velocidades originais.
@export_category("Inteligencia artificial")
@export var raio_deteccao: float = 180.0
@export var distancia_retorno: float = 240.0
@export var patrulha_ativa: bool = false
@export var raio_patrulha: float = 72.0
var ponto_inicial: Vector2
var destino_patrulha: Vector2
var espera_patrulha: float = 2.0
var andando_patrulha: bool = false
var tempo_patrulha: float = 0.0
var estado_ia: String = "repouso"
var rng_patrulha: RandomNumberGenerator=RandomNumberGenerator.new()
func _ready() -> void:
	super._ready()
	ponto_inicial=global_position
	destino_patrulha=ponto_inicial
	rng_patrulha.randomize()
	espera_patrulha=rng_patrulha.randf_range(1.8,4.0)
func _physics_process(delta: float) -> void:
	var movimento: Vector2=Vector2.ZERO
	if not esta_morto:
		var alvo: CharacterBody2D=_procurar_alvo()
		if is_instance_valid(alvo):
			estado_ia="perseguir"
			andando_patrulha=false
			espera_patrulha=2.0
			var ate_alvo: Vector2=alvo.global_position-global_position
			if not atacando: olhar_para(ate_alvo)
			if ate_alvo.length()<=alcance_ataque:
				estado_ia="atacar"
				iniciar_ataque()
			else:
				var fase: Node=get_tree().get_first_node_in_group("fase_atual")
				movimento=fase.direcao_ia(self,alvo.global_position) if fase!=null else ate_alvo.normalized()
		elif patrulha_ativa:
			movimento=_patrulhar(delta)
		elif global_position.distance_to(ponto_inicial)>5.0:
			estado_ia="retornar"
			var fase: Node=get_tree().get_first_node_in_group("fase_atual")
			movimento=fase.direcao_ia(self,ponto_inicial) if fase!=null else global_position.direction_to(ponto_inicial)
		else: estado_ia="repouso"
	else: estado_ia="morto"
	mover(movimento,delta)
func _patrulhar(delta: float) -> Vector2:
	var fase: Node=get_tree().get_first_node_in_group("fase_atual")
	if fase==null or atacando or tempo_dano>0: return Vector2.ZERO
	if not andando_patrulha:
		estado_ia="repouso"
		espera_patrulha-=delta
		if espera_patrulha>0: return Vector2.ZERO
		espera_patrulha=rng_patrulha.randf_range(1.8,4.5)
		for tentativa in range(16):
			var alvo: Vector2=ponto_inicial+Vector2(rng_patrulha.randi_range(-2,2),rng_patrulha.randi_range(-2,2))*32
			if alvo.distance_to(ponto_inicial)>raio_patrulha or alvo.distance_to(global_position)<18: continue
			if fase.altura_em(alvo)!=altura_nivel: continue
			if fase.direcao_ia(self,alvo).is_zero_approx(): continue
			destino_patrulha=alvo
			andando_patrulha=true
			tempo_patrulha=0
			break
		return Vector2.ZERO
	tempo_patrulha+=delta
	if global_position.distance_to(destino_patrulha)<7 or tempo_patrulha>6.5:
		andando_patrulha=false
		estado_ia="repouso"
		return Vector2.ZERO
	estado_ia="patrulhar"
	return fase.direcao_ia(self,destino_patrulha)*0.32
func _procurar_alvo() -> CharacterBody2D:
	var escolhido: CharacterBody2D
	var distancia_minima: float=raio_deteccao
	if global_position.distance_to(ponto_inicial)>distancia_retorno: return null
	for heroi in get_tree().get_nodes_in_group("herois"):
		if heroi.esta_morto or not _tem_linha_de_visao(heroi.global_position): continue
		var distancia: float=global_position.distance_to(heroi.global_position)
		if distancia<distancia_minima:
			distancia_minima=distancia
			escolhido=heroi
	return escolhido
