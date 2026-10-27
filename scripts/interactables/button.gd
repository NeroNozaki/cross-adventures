extends Area2D

@onready var animacao: AnimatedSprite2D = $animation
var corpos_no_botao: int = 0
var pressionado: bool = false
var em_transicao: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(PhysicsLayers.BUTTON, true)
	set_collision_mask_value(PhysicsLayers.HERO, true)
	body_entered.connect(_ao_corpo_entrar)
	body_exited.connect(_ao_corpo_sair)
	animacao.play("1-not_pressed")

func _ao_corpo_entrar(_body: Node2D) -> void:
	corpos_no_botao += 1
	if corpos_no_botao == 1 and not pressionado and not em_transicao:
		_pressionar()

func _ao_corpo_sair(_body: Node2D) -> void:
	corpos_no_botao -= 1
	if corpos_no_botao == 0 and pressionado and not em_transicao:
		_soltar()

func _pressionar() -> void:
	em_transicao = true
	em_transicao = false
	if corpos_no_botao >= 1:  # still on button
		animacao.play("3-pressed")
		pressionado = true
	else:  # left during transition
		_soltar()

func _soltar() -> void:
	em_transicao = true
	animacao.play("2-transition")
	await get_tree().create_timer(0.5).timeout
	em_transicao = false
	if corpos_no_botao == 0:
		animacao.play("1-not_pressed")
		pressionado = false
	else:
		_pressionar()
