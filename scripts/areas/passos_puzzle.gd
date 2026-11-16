extends Node
var anterior: Vector2
var distancia := 0.0
var tempo := 0.0
var escala: Vector2
@onready var heroi: Heroi = get_parent()
@onready var sprite: AnimatedSprite2D = heroi.get_node("Visual/AnimatedSprite2D")
func _ready() -> void:
	anterior = heroi.global_position
	escala = sprite.scale
func _process(delta: float) -> void:
	var deslocamento := heroi.global_position.distance_to(anterior)
	anterior = heroi.global_position
	tempo += delta
	if String(sprite.animation).begins_with("walk") and not heroi.pulando:
		sprite.scale = escala
		if deslocamento < 10:
			distancia += deslocamento
		var frames := sprite.sprite_frames.get_frame_count(sprite.animation)
		sprite.pause()
		sprite.set_frame_and_progress(int(distancia/8)%frames,fmod(distancia/8,1))
	elif String(sprite.animation).begins_with("idle"):
		sprite.scale = escala*Vector2(1,1+sin(tempo*2)*0.006)
	else:
		sprite.scale = escala
