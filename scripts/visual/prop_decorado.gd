extends Node2D
## Suporte sob o atlas original: silhueta do item e pixels nativos permanecem inteiros.
func _ready() -> void:
	show_behind_parent=true
func _draw() -> void:
	draw_rect(Rect2(-8,7,16,3),Color(0.07,0.08,0.13,0.38))
	draw_rect(Rect2(-7,5,14,4),Color("484553"))
	draw_rect(Rect2(-6,5,12,1),Color("a39a91"))
	draw_rect(Rect2(-6,8,12,1),Color("343440"))
	for x in [-6,5]: draw_rect(Rect2(x,6,1,1),Color("817f85"))
