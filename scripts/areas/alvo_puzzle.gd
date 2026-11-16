extends Node2D
## Receptor grande: somente projéteis de Otto entram na lógica do puzzle.
@export var indice := 0
var ativo := false
var confirmado := false
var tempo := 0.0
var aviso_restante := 0.0
@onready var imagem: AnimatedSprite2D = $Imagem

func _process(delta: float) -> void:
	tempo += delta
	aviso_restante = maxf(0,aviso_restante-delta)
	var revelado := ativo or confirmado
	imagem.position.y = lerpf(imagem.position.y,(-12.0 if revelado else 1.0),minf(1,delta*10))+sin(tempo*2.2+indice)*0.1
	imagem.modulate.a = move_toward(imagem.modulate.a,1.0 if revelado else 0.15,delta*4)
	imagem.play("gold" if confirmado else ("blue" if ativo else "red"))
	queue_redraw()

func receber_projetil(tiro: Node) -> String:
	var sala := get_tree().current_scene
	if confirmado:
		return "consumir"
	if not ativo:
		if aviso_restante == 0:
			sala.avisar("Nico precisa preparar a trava com F." if sala.mapa_id == 2 or (sala.mapa_id == 4 and not sala.roda_ativa) else "Nico precisa ficar na pedra para revelar o alvo.")
			aviso_restante = 2.0
		return "consumir"
	if sala.mapa_id == 4 and (not tiro.carregado or tiro.ricochetes < 1):
		sala.avisar("Carregue a esfera e use o espelho: o tiro precisa rebater uma vez.")
		return "consumir"
	sala.alvo_atingido(indice)
	return "consumir"

func _draw() -> void:
	if ativo or confirmado:
		var cor := Color(0.4,0.9,1,0.3) if not confirmado else Color(1,0.8,0.3,0.45)
		draw_arc(Vector2(0,-12),19,0,TAU,24,cor,1)
		draw_line(Vector2(-23,-12),Vector2(-19,-12),cor,2)
		draw_line(Vector2(19,-12),Vector2(23,-12),cor,2)
