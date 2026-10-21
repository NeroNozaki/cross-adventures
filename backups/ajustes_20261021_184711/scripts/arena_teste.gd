extends Node2D
## Arena cooperativa local: Guerreiro e Robo recebem comandos independentes.

@onready var guerreiro: CharacterBody2D = $Personagens/Guerreiro
@onready var robo: CharacterBody2D = $Personagens/Robo
@onready var texto: Label = $Interface/Painel/Margem/Texto

func _ready() -> void:
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reiniciar"):
		get_tree().reload_current_scene()

func _process(_delta: float) -> void:
	var vivos: int = 0
	for vilao in get_tree().get_nodes_in_group("viloes"):
		if not vilao.esta_morto:
			vivos += 1
	var estado: String = "Inimigos: %d/2" % vivos
	if guerreiro.esta_morto and robo.esta_morto:
		estado = "Equipe derrotada"
	elif vivos == 0:
		estado = "Vitoria!"
	texto.text = "Guerreiro %d/%d PV   |   Robo %d/%d PV\nGuerreiro: WASD + Espaco/J atacar + Shift escudo\nRobo: Setas + Enter atacar\n%s   |   R: reiniciar" % [guerreiro.vida_atual, guerreiro.vida_maxima, robo.vida_atual, robo.vida_maxima, estado]
	$Marcador.position = guerreiro.position + Vector2(0, 8)
	$Marcador.visible = not guerreiro.esta_morto
	$MarcadorRobo.position = robo.position + Vector2(0, 8)
	$MarcadorRobo.visible = not robo.esta_morto

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 400), Color("17252a"))
	draw_rect(Rect2(22, 94, 596, 282), Color("334a43"))
	for x in range(22, 619, 24):
		draw_line(Vector2(x, 94), Vector2(x, 376), Color("3b544b"))
	for y in range(94, 377, 24):
		draw_line(Vector2(22, y), Vector2(618, y), Color("3b544b"))
	draw_rect(Rect2(22, 94, 596, 282), Color("72806a"), false, 3.0)
