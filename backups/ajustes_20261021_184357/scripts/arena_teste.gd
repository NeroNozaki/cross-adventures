extends Node2D
## Cena de teste independente: os quatro personagens sao instancias reutilizaveis.

@onready var herois: Array[CharacterBody2D] = [$Personagens/Guerreiro, $Personagens/Robo]
@onready var texto: Label = $Interface/Painel/Margem/Texto
var selecionado: int = 0

func _ready() -> void:
	for personagem in $Personagens.get_children():
		personagem.morreu.connect(_ao_morrer)
	_selecionar(0)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("trocar_heroi"):
		_selecionar((selecionado + 1) % herois.size())
	if event.is_action_pressed("reiniciar"):
		get_tree().reload_current_scene()

func _process(_delta: float) -> void:
	var ativo: CharacterBody2D = herois[selecionado]
	var vivos: int = 0
	for vilao in get_tree().get_nodes_in_group("viloes"):
		if not vilao.esta_morto:
			vivos += 1
	var estado: String = "Inimigos: %d/2" % vivos
	if herois[0].esta_morto and herois[1].esta_morto:
		estado = "Equipe derrotada. R para recomecar."
	elif vivos == 0:
		estado = "Vitoria! R para recomecar."
	texto.text = "ARENA DE TESTE  |  %s  %d/%d PV\nWASD / Setas: mover   Espaco / J: atacar   Tab: trocar   R: reiniciar\n%s" % [ativo.nome_personagem, ativo.vida_atual, ativo.vida_maxima, estado]
	$Marcador.position = ativo.position + Vector2(0, 8)
	$Marcador.visible = not ativo.esta_morto

func _selecionar(indice: int) -> void:
	if herois[indice].esta_morto:
		return
	selecionado = indice
	for heroi in herois:
		heroi.controlado = heroi == herois[selecionado]
		heroi.lider = herois[selecionado]

func _ao_morrer(personagem: CharacterBody2D) -> void:
	if personagem == herois[selecionado]:
		_selecionar((selecionado + 1) % herois.size())

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 400), Color("17252a"))
	draw_rect(Rect2(22, 94, 596, 282), Color("334a43"))
	for x in range(22, 619, 24):
		draw_line(Vector2(x, 94), Vector2(x, 376), Color("3b544b"))
	for y in range(94, 377, 24):
		draw_line(Vector2(22, y), Vector2(618, y), Color("3b544b"))
	draw_rect(Rect2(22, 94, 596, 282), Color("72806a"), false, 3.0)
