extends Node2D
## Roda travada: golpe de Nico (F), com a ajuda necessária da dupla.
var equipe := 1
var altura_nivel := 0
var pulando := false
var esta_morto := false
var vida_atual := 1
var acionada := false

func receber_projetil(_tiro: Node) -> String:
	if acionada:
		return "ignorar"
	get_tree().current_scene.avisar("Esta trava precisa do golpe de Nico. Aproximem-se e apertem F.")
	return "consumir"

func receber_dano(_dano: int, _origem: Vector2) -> void:
	if acionada:
		return
	var sala := get_tree().current_scene
	if not sala.pode_acionar_roda():
		return
	acionada = true
	vida_atual = 0
	$Imagem.modulate = Color("#ffd781")
	var t := create_tween()
	t.tween_property($Imagem,"rotation",PI/2,0.5).set_trans(Tween.TRANS_BACK)
	sala.acionar_roda()
