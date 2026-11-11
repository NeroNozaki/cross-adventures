extends Node2D

var tempo := 0.0

func _process(delta: float) -> void:
	tempo += delta
	queue_redraw()

func _draw() -> void:
	# Ondas discretas restritas ao canal, com abertura no tabuleiro da ponte.
	for i in 24:
		var y := fmod(i*23.0+tempo*9.0,520)
		if y > 231 and y < 297:
			continue
		var x := 484+fmod(i*17.0,53)
		var largura := 9+sin(tempo+i)*3
		draw_line(Vector2(x,y).round(),Vector2(x+largura,y).round(),Color(0.76,0.92,1,0.30),1)
	# Marcas de pedra conectam a placa à base da torre.
	for i in 8:
		var p := Vector2(262+i*18,264-i*8)
		draw_rect(Rect2(p.round(),Vector2(6,3)),Color("#918878"))
	# Identificação legível e imóvel da placa.
	draw_line(Vector2(235,259),Vector2(235,269),Color("#fff1b0"),2)
	draw_line(Vector2(235,269),Vector2(244,269),Color("#fff1b0"),2)
