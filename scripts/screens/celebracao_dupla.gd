extends Node2D
## Atores da vinheta final: saem do portão, pulam e comemoram em tempo real.
const NICO = preload("res://recursos/personagens/player1_fixed.tres")
const OTTO = preload("res://recursos/personagens/player2.tres")
const BRACOS = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Character/Skeleton/SeparateAnim/Item.png")
const CAPA = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Character/Skeleton/SeparateAnim/NicoCape.svg")
var sprites: Array[AnimatedSprite2D] = []
var alturas: Array[float] = []
var origens: Dictionary = {}
var sombras: Node2D
var efeitos: Node2D
var capa: Sprite2D
var baloes: Array[Label] = []
var confetes: Array[Dictionary] = []
var chao: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var saltos: Array[float] = [0.0,0.0]
var festa := false
var tempo := 0.0
var area: Rect2

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sombras = Node2D.new()
	sombras.draw.connect(_desenhar_sombras)
	add_child(sombras)
	for fonte in [NICO,OTTO]:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = fonte.duplicate()
		sprite.centered = false
		sprite.play("walk_left")
		add_child(sprite)
		sprites.append(sprite)
		alturas.append(fonte.get_frame_texture("idle_down",0).get_image().get_used_rect().size.y)
	sprites[0].sprite_frames.add_animation("festejar")
	sprites[0].sprite_frames.set_animation_speed("festejar",3)
	sprites[0].sprite_frames.add_frame("festejar",BRACOS,2)
	sprites[0].sprite_frames.add_frame("festejar",NICO.get_frame_texture("idle_down",0))
	capa = Sprite2D.new()
	capa.texture = CAPA
	capa.scale = Vector2.ONE * 0.75
	capa.z_index = -1
	sprites[0].add_child(capa)
	efeitos = Node2D.new()
	efeitos.draw.connect(_desenhar_confetes)
	add_child(efeitos)
	for frase in ["Conseguimos!", "Bip-bip! Amigos!"]:
		var balao := Label.new()
		balao.text = frase
		balao.add_theme_font_size_override("font_size",12)
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.025,0.08,0.10,0.82)
		estilo.set_corner_radius_all(5)
		estilo.set_content_margin_all(6)
		balao.add_theme_stylebox_override("normal",estilo)
		balao.mouse_filter = Control.MOUSE_FILTER_IGNORE
		balao.hide()
		add_child(balao)
		baloes.append(balao)

func atualizar(relogio: float, delta: float, retangulo: Rect2) -> void:
	tempo = relogio
	area = retangulo
	for i in sprites.size():
		var sprite := sprites[i]
		var percurso := smoothstep(0.25 + i * 0.3,3.15 + i * 0.3,tempo)
		var destino := 0.43 + i * 0.12
		chao[i] = (area.position + Vector2(lerpf(0.79,destino,percurso),lerpf(0.667,0.697,percurso)) * area.size).round()
		saltos[i] = _altura_salto(i)
		var animacao := "walk_left" if percurso < 1 else ("festejar" if i == 0 else ("walk_down" if tempo < 6 else "idle_down"))
		if sprite.animation != animacao:
			sprite.play(animacao)
		_alinhar(sprite,i)
		var escala := area.size.y * 0.105 / alturas[i]
		sprite.scale = Vector2(escala * (0.9 if i == 0 else 1.0),escala)
		sprite.position = chao[i] - Vector2(0,saltos[i])
		if percurso >= 1:
			sprite.position.x += sin(tempo * 4 + i) * 1.1
			sprite.rotation = sin(tempo * 5) * 0.025 if i == 1 and tempo < 6 else 0
		sprite.modulate.a = smoothstep(0.25 + i * 0.3,0.6 + i * 0.3,tempo)
		baloes[i].position = sprite.position + Vector2(-86 if i == 0 else 8,-68)
	baloes[0].visible = tempo > 3.5 and tempo < 5.5
	baloes[1].visible = tempo > 4.4 and tempo < 6.1
	capa.position = sprites[0].offset + Vector2(4,9)
	capa.rotation = sin(tempo * 6) * 0.06
	if tempo >= 3.5 and not festa:
		festa = true
		_lancar_confetes()
	for i in range(confetes.size()-1,-1,-1):
		var p := confetes[i]
		p.vida -= delta
		p.v.y += delta * 48
		p.p += p.v * delta
		if p.vida <= 0:
			confetes.remove_at(i)
	sombras.queue_redraw()
	efeitos.queue_redraw()

func _alinhar(sprite: AnimatedSprite2D, indice: int) -> void:
	var chave := str(indice) + str(sprite.animation)
	if not origens.has(chave):
		var base := 0.0
		var largura := 0.0
		for i in sprite.sprite_frames.get_frame_count(sprite.animation):
			var textura := sprite.sprite_frames.get_frame_texture(sprite.animation,i)
			base = maxf(base,textura.get_image().get_used_rect().end.y)
			largura = textura.get_width() * 0.5
		origens[chave] = Vector2(largura,base)
	sprite.offset = -origens[chave]

func _altura_salto(indice: int) -> float:
	for inicio in [3.6,4.4,5.25]:
		var u: float = (tempo-inicio-indice*0.1)/0.6
		if u > 0 and u < 1:
			return sin(u*PI)*13
	return maxf(0,sin(tempo*2+indice)*0.4) if tempo > 6 else 0.0

func _lancar_confetes() -> void:
	var cores := [Color("ffd681"),Color("8ad7e0"),Color("e7a0ba"),Color("a9d690")]
	for i in 72:
		confetes.append({"p":chao[i%2]-Vector2(0,26),"v":Vector2(randf_range(-64,64),randf_range(-110,-40)),"vida":randf_range(1.5,2.8),"cor":cores[i%4]})

func _desenhar_sombras() -> void:
	for i in sprites.size():
		sombras.draw_set_transform(chao[i],0,Vector2(1,0.22))
		sombras.draw_circle(Vector2.ZERO,13-saltos[i]*0.12,Color(0.015,0.035,0.04,0.42*sprites[i].modulate.a))
		sombras.draw_set_transform(Vector2.ZERO)

func _desenhar_confetes() -> void:
	for p in confetes:
		if p.p.y < area.position.y + area.size.y*0.4:
			continue
		var cor: Color = p.cor
		cor.a = minf(1,p.vida*2)
		var tamanho := Vector2(2,1) if int(p.vida*8)%2 == 0 else Vector2(1,2)
		efeitos.draw_rect(Rect2(Vector2(p.p).round(),tamanho),cor)
