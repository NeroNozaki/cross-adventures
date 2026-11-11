extends Node2D
## Ambientação local: decoração sem colisão, fora dos mecanismos.
const FOGO = preload("res://assets/mapa/CRAFTPIX_DUNGEON/fire_animation.png")
var tochas: Array[AnimatedSprite2D] = []
var tempo := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var quadros := SpriteFrames.new()
	quadros.set_animation_speed("default",7)
	for i in 4:
		var recorte := AtlasTexture.new()
		recorte.atlas = FOGO
		recorte.region = Rect2(88,i*48,44,48)
		quadros.add_frame("default",recorte)
	for ponto in [Vector2(48,24),Vector2(336,24),Vector2(48,240),Vector2(336,312),Vector2(840,24),Vector2(840,528),Vector2(48,528),Vector2(672,528),Vector2(48,-552),Vector2(648,-552),Vector2(888,-240)]:
		var chama := AnimatedSprite2D.new()
		chama.sprite_frames = quadros
		chama.position = ponto
		chama.scale = Vector2.ONE*0.5
		chama.z_index = 2
		add_child(chama)
		chama.play()
		chama.frame = tochas.size()%4
		tochas.append(chama)

func _process(delta: float) -> void:
	tempo += delta
	queue_redraw()

func _draw() -> void:
	# Discos translúcidos pequenos: luz quente junto às paredes.
	for i in tochas.size():
		var ponto := tochas[i].position
		var pulso := 0.9+sin(tempo*4+i*2)*0.1
		draw_set_transform(ponto)
		draw_rect(Rect2(-7,7,14,3),Color(0,0,0,0.28))
		draw_rect(Rect2(-5,0,10,9),Color("#34374d"))
		draw_rect(Rect2(-6,-1,12,3),Color("#85889e"))
		draw_rect(Rect2(-4,3,2,5),Color("#60677c"))
		draw_set_transform(Vector2.ZERO)
		for raio in [28,20,12]:
			draw_circle(ponto,raio,Color(1.0,0.65,0.23,0.025*pulso))
	# Faixa de mosaico no salão inicial, sem cobrir placas nem passagem.
	for x in range(192,648,12):
		draw_rect(Rect2(x,548,7,2),Color("#9e916f"))
		draw_rect(Rect2(x,552,7,1),Color("#383c51"))
