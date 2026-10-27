extends Node2D
## Varredura circular continua contra paredes e areas de dano dos inimigos.
## Ignora os herois e desaparece no quarto contato com o cenario.

const IMPACTO: PackedScene = preload("res://cenas/combate/impacto_projetil.tscn")
@export var max_ricochetes: int = 4
@export var tempo_de_vida: float = 12.0
var emissor: CharacterBody2D
var direcao: Vector2 = Vector2.RIGHT
var altura_nivel: int = 0
var elemento: String = "normal"
var carregado: bool = false
var dano: int = 18
var raio: float = 4.0
var velocidade: float = 340.0
var ricochetes: int = 0
var encerrado: bool = false
var som_ricochete: AudioStream
var rastro: Array[Vector2] = []
@onready var varredura: ShapeCast2D = $Varredura
signal ricocheteou(total: int)
signal atingiu(alvo: Node)

func _ready() -> void:
	add_to_group("projeteis")
	top_level = true
	direcao = direcao.normalized() if direcao.length_squared() > 0.001 else Vector2.RIGHT
	var forma: CircleShape2D = CircleShape2D.new()
	forma.radius = raio
	varredura.shape = forma

func _physics_process(delta: float) -> void:
	if encerrado:
		return
	if not is_instance_valid(emissor) or emissor.esta_morto:
		_encerrar(false)
		return
	tempo_de_vida -= delta
	if tempo_de_vida <= 0.0:
		_encerrar(false)
		return
	rastro.append(global_position)
	if rastro.size() > 8:
		rastro.pop_front()
	var restante: float = velocidade * delta
	for tentativa in range(6):
		if restante <= 0.01 or encerrado:
			break
		varredura.target_position = direcao * restante
		varredura.force_shapecast_update()
		if not varredura.is_colliding():
			global_position += direcao * restante
			break
		var fracao: float = clampf(varredura.get_closest_collision_safe_fraction(), 0.0, 1.0)
		global_position += direcao * restante * fracao
		restante *= 1.0 - fracao
		var colisor: Object = varredura.get_collider(0)
		var normal: Vector2 = varredura.get_collision_normal(0)
		var inteligente: Object = colisor.get_parent() if colisor is Area2D else colisor
		if inteligente != null and inteligente.has_method("tipo") and inteligente.tipo() == "espelho":
			normal = inteligente.global_transform.y.normalized()
			if direcao.dot(normal) > 0: normal = -normal
		if inteligente != null and inteligente.has_method("receber_projetil"):
			var resultado: String = inteligente.receber_projetil(self)
			if resultado == "consumir":
				_encerrar(true)
				break
			if resultado == "ignorar":
				varredura.add_exception_rid(colisor.get_rid())
				continue
		if colisor.has_meta("altura") and int(colisor.get_meta("altura")) >= 0 and int(colisor.get_meta("altura")) != altura_nivel:
			varredura.add_exception_rid(colisor.get_rid())
			continue
		if colisor is Area2D:
			var alvo: Node = colisor.get_parent()
			if alvo.has_method("receber_dano") and alvo.equipe != emissor.equipe and not alvo.esta_morto and int(alvo.get("altura_nivel")) == altura_nivel and alvo.get("pulando") != true:
				var antes: int = alvo.vida_atual
				alvo.receber_dano(dano, global_position - direcao * 8.0)
				if alvo.vida_atual < antes and is_instance_valid(emissor):
					emissor.audio.tocar(&"acerto")
				atingiu.emit(alvo)
				_encerrar(true)
			else:
				varredura.add_exception_rid(colisor.get_rid())
		else:
			if normal.length_squared() < 0.01:
				normal = -direcao
			normal = normal.normalized()
			if direcao.dot(normal) >= -0.001:
				global_position += normal * 0.8
				continue
			direcao = direcao.bounce(normal).normalized()
			ricochetes += 1
			_criar_impacto(true)
			ricocheteou.emit(ricochetes)
			if ricochetes >= max_ricochetes:
				_encerrar(false)
				break
			global_position += normal * 0.6
	queue_redraw()

func _criar_impacto(com_som: bool) -> void:
	var efeito: Node2D = IMPACTO.instantiate()
	efeito.cor = Color("ffce65") if carregado else Color("79eaff")
	efeito.som = som_ricochete if com_som else null
	get_parent().add_child(efeito)
	efeito.global_position = global_position - Vector2(0, 16 * altura_nivel)

func _encerrar(com_efeito: bool) -> void:
	if encerrado:
		return
	encerrado = true
	set_physics_process(false)
	if com_efeito:
		_criar_impacto(false)
	hide()
	queue_free()

func _draw() -> void:
	var paleta: Dictionary = {"normal": Color("79eaff"), "fogo": Color("ff9a61"), "gelo": Color("83e2ff"), "choque": Color("cfabff"), "onda": Color("6af3c0")}
	var cor: Color = paleta.get(elemento, Color("79eaff"))
	if carregado:
		cor = cor.lightened(0.25)
	draw_set_transform(Vector2(0, -16 * altura_nivel))
	for i in range(1, rastro.size()):
		var alfa: float = float(i) / float(rastro.size()) * 0.45
		draw_line(to_local(rastro[i - 1]), to_local(rastro[i]), Color(cor, alfa), raio * 1.1, true)
	draw_circle(Vector2.ZERO, raio * 1.7, Color(cor, 0.15))
	draw_circle(Vector2.ZERO, raio, cor)
	draw_circle(Vector2(-raio * 0.25, -raio * 0.25), raio * 0.45, Color("f3ffff"))
	# Quatro pequenos pontos indicam os contatos com parede restantes.
	for i in range(max_ricochetes - ricochetes):
		draw_circle(Vector2(float(i) * 3.0 - 4.5, raio + 4.0), 0.8, Color(cor, 0.8))
