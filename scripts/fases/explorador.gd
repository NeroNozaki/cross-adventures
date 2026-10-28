extends Node2D
@export var caminho: PackedVector2Array = PackedVector2Array()
var trecho: int = 0
var t: float = 0.0
func _process(delta: float) -> void:
	if caminho.size() < 2:
		return
	t += delta * 0.6
	if t >= 1:
		t -= 1
		trecho = (trecho + 1) % caminho.size()
	position = caminho[trecho].lerp(caminho[(trecho + 1) % caminho.size()], t)
	$Sprite.position.y = -8.0 - sin(t * PI) * 8.0
