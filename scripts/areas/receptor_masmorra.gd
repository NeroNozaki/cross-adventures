extends Node2D
## A cor do receptor segue o estado do mecanismo.
const TALHA := "res://assets/mapa/CRAFTPIX_DUNGEON/talha_masmorra.svg"
const TONS := {&"red": Color("ff9376"), &"blue": Color("78daf2"), &"gold": Color("ffda73")}
var gema: Sprite2D
var pedra: Sprite2D
var centro: Vector2

func montar(alvo: Vector2, tinta: Color) -> void:
	centro = alvo
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var atlas := load(TALHA) as Texture2D
	pedra = _parte(atlas, Rect2(48, 0, 28, 36))
	pedra.position = centro + Vector2(0, 4)
	pedra.scale = Vector2(0.84, 0.76)
	pedra.self_modulate = tinta
	gema = _parte(atlas, Rect2(80, 0, 20, 20))
	gema.position = centro
	gema.scale = Vector2(0.76, 0.76)

func _parte(atlas: Texture2D, regiao: Rect2) -> Sprite2D:
	var parte := Sprite2D.new()
	var quadro := AtlasTexture.new()
	quadro.atlas = atlas
	quadro.region = regiao
	quadro.filter_clip = true
	parte.texture = quadro
	add_child(parte)
	return parte

func atualizar(estado: StringName, tempo: float) -> Color:
	var cor: Color = TONS.get(estado, TONS[&"red"])
	var brilho := 0.10 + sin(tempo * 2.7) * 0.055
	gema.self_modulate = cor.lightened(brilho)
	gema.position.y = centro.y - 0.45 + sin(tempo * 1.85) * 0.65
	return cor
