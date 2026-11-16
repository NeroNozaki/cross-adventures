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
	# Cristal e coluna originais da fase 3; o estado muda a cor, sem esconder a peça.
	imagem.modulate.a = move_toward(imagem.modulate.a,1.0 if ativo or confirmado else 0.85,delta*4)
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
		var cor := Color(0.4,0.9,1,0.25) if not confirmado else Color(1,0.8,0.3,0.3)
		cor.a *= 0.75+sin(tempo*2.2+indice)*0.25
		# Brilho discreto em pixels, sem moldura de mira ao redor do cristal.
		for lado in [-1,1]:
			draw_rect(Rect2(lado*13-1,-14,2,2),cor)
			draw_rect(Rect2(lado*10-1,-22,2,2),cor)
