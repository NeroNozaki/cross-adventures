extends "res://scripts/personagens/personagem_base.gd"
## Dois controles independentes: cada instancia usa seu proprio prefixo de acoes.

@export var controlado: bool = true
@export var prefixo_controle: String = "guerreiro"

func _physics_process(delta: float) -> void:
	var movimento: Vector2 = Vector2.ZERO
	if not esta_morto and controlado:
		movimento = Input.get_vector(prefixo_controle + "_esquerda", prefixo_controle + "_direita", prefixo_controle + "_cima", prefixo_controle + "_baixo")
		if movimento.length_squared() > 0.01 and not atacando:
			olhar_para(movimento)
		var acao_escudo: String = prefixo_controle + "_defender"
		definir_defesa(InputMap.has_action(acao_escudo) and Input.is_action_pressed(acao_escudo))
		if Input.is_action_just_pressed(prefixo_controle + "_atacar"):
			iniciar_ataque()
	else:
		definir_defesa(false)
	mover(movimento, delta)
