extends Node2D
## A cadência é medida no chão, inclusive quando o personagem encontra uma parede.

const POEIRA = preload("res://assets/mapa/passos_valley.png")
var anterior: Vector2
var distancia := 0.0
var desde_passo := 0.0
var marcas: Array[Dictionary] = []
@onready var heroi: Heroi = get_parent()
@onready var sprite: AnimatedSprite2D = heroi.get_node("Visual/AnimatedSprite2D")

func _ready() -> void:
	anterior = heroi.global_position
	z_index = -1

func _process(delta: float) -> void:
	var deslocamento := heroi.global_position.distance_to(anterior)
	anterior = heroi.global_position
	var andando: bool = deslocamento > 0.02 and deslocamento < 12 and not heroi.pulando and not heroi.caindo
	if andando and String(sprite.animation).begins_with("walk"):
		distancia += deslocamento
		var quadros := sprite.sprite_frames.get_frame_count(sprite.animation)
		var fase := distancia / 4.5
		sprite.pause()
		sprite.set_frame_and_progress(int(fase) % quadros, fmod(fase,1.0))
		desde_passo += deslocamento
		if desde_passo >= 16:
			desde_passo = 0
			marcas.append({"ponto":heroi.global_position,"vida":0.30})
	for marca in marcas:
		marca.vida -= delta
	marcas = marcas.filter(func(marca): return marca.vida > 0)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0,1),0,Vector2(1,0.4))
	draw_circle(Vector2.ZERO,9,Color(0.08,0.13,0.12,0.28))
	draw_set_transform(Vector2.ZERO)
	for marca in marcas:
		var quadro := mini(2,int((0.30-float(marca.vida))*10))
		var ponto := to_local(marca.ponto).round()
		draw_texture_rect_region(POEIRA,Rect2(ponto-Vector2(5,7),Vector2(10,10)),Rect2(quadro*16,0,16,16),Color(0.79,0.70,0.52,float(marca.vida)*1.7))
