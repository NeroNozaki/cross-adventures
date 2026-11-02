extends Node2D

var robo

func _ready() -> void:
	robo = $Personagens/Robo

func _process(delta: float) -> void:
	$MarcadorRobo.position = robo.position + Vector2(0, 8)
	$MarcadorRobo.visible = not robo.esta_morto
