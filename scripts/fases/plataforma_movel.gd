@tool
extends Node2D
@export var amplitude: Vector2 = Vector2(48, 0)
@export var periodo: float = 5.0
@export var tamanho: Vector2 = Vector2(64, 32)
@export var altura: int = 1
var origem: Vector2
var anterior: Vector2
var fase_t: float = 0.0

func _ready() -> void:
	origem = position
	anterior = global_position

func avancar(delta: float, atores: Array) -> void:
	var antes: Rect2 = Rect2(global_position - tamanho / 2.0, tamanho)
	anterior = global_position
	fase_t += delta
	position = origem + amplitude * sin(fase_t * TAU / periodo)
	var deslocamento: Vector2 = global_position - anterior
	for ator in atores:
		if not ator.esta_morto and not ator.pulando and ator.altura_nivel == altura and antes.has_point(ator.global_position):
			var fase: Node = get_tree().get_first_node_in_group("fase_atual")
			if int(fase.grade.get(fase.celula(ator.global_position), -1)) != altura:
				ator.global_position += deslocamento

func contem(p: Vector2) -> bool:
	return Rect2(global_position - tamanho / 2.0, tamanho).grow(2).has_point(p)

func _draw() -> void:
	var r: Rect2 = Rect2(-tamanho / 2.0 + Vector2(0, -16 * altura), tamanho)
	draw_rect(r.grow(3), Color("17141e"))
	draw_rect(r, Color("675348"))
	for x in range(int(r.position.x) + 4, int(r.end.x), 8):
		draw_line(Vector2(x, r.position.y + 2), Vector2(x, r.end.y - 2), Color("a58b67"), 2)
	for p in [r.position+Vector2(3,3),r.position+Vector2(3,r.size.y-3),r.end-Vector2(3,3),r.position+Vector2(r.size.x-3,3)]:
		draw_rect(Rect2(p-Vector2.ONE,Vector2(2,2)),Color("91c4bd"))
