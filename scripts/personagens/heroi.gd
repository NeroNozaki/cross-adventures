extends PersonagemBase
class_name Heroi
## Dois controles independentes: cada instancia usa seu proprio prefixo de acoes.

@export var controlado: bool = true
@export var prefixo_controle: String = "guerreiro"

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	var movimento: Vector2 = Vector2.ZERO
	if not esta_morto and not caindo and controlado:
		movimento = Input.get_vector(prefixo_controle + "_esquerda", prefixo_controle + "_direita", prefixo_controle + "_cima", prefixo_controle + "_baixo")
		if movimento.length_squared() > 0.01 and not atacando and not defendendo and not esta_empurrado():
			olhar_para(movimento)
		if Input.is_action_just_pressed(prefixo_controle + "_atacar"):
			iniciar_ataque()
	mover(movimento, delta)
