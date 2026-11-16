extends Node2D
## Alavanca de base fixa: apenas a haste troca de lado sobre o próprio encaixe.
const ARTE = preload("res://recursos/arte_objetos_puzzle.gd")
var equipe := 1
var altura_nivel := 0
var pulando := false
var esta_morto := false
var vida_atual := 1
var acionada := false
var haste: Sprite2D

func _ready() -> void:
	var base: Sprite2D = $Imagem
	base.texture = ARTE.parte_alavanca(true)
	base.position = Vector2(0,-7)
	base.rotation = 0
	haste = Sprite2D.new()
	haste.name = "Haste"
	haste.texture = ARTE.parte_alavanca(false)
	haste.centered = false
	haste.offset = Vector2(-5,-5)
	haste.position = Vector2(-3,-2.5)
	haste.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	base.add_child(haste)

func receber_projetil(_tiro: Node) -> String:
	if acionada:
		return "ignorar"
	get_tree().current_scene.avisar("Nico puxa a alavanca: use F ou o X azul do controle.")
	return "consumir"

func receber_dano(_dano: int, _origem: Vector2) -> void:
	if acionada:
		return
	var sala := get_tree().current_scene
	if not sala.pode_acionar_roda():
		return
	acionada = true
	vida_atual = 0
	# Poses curtas de pixel art, sem girar a base nem dar uma volta com o sprite.
	haste.scale.x = 0.35
	await get_tree().create_timer(0.07,false).timeout
	haste.scale.x = -0.35
	await get_tree().create_timer(0.07,false).timeout
	haste.scale.x = -1
	sala.acionar_roda()
