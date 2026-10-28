extends Camera2D
@export var visao_geral: bool=false
var inicializada: bool=false
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_V:
		visao_geral=not visao_geral
func _process(delta: float) -> void:
	var fase: Node2D=get_parent()
	if fase.dados.is_empty() or not is_instance_valid(fase.lucas): return
	var tela: Vector2=get_viewport_rect().size
	var destino: Vector2
	var escala: float
	limit_left=-100000 if visao_geral else 0
	limit_top=-100000 if visao_geral else -32
	limit_right=100000 if visao_geral else int(fase.dados.largura)*32
	limit_bottom=100000 if visao_geral else int(fase.dados.altura)*32+32
	if visao_geral:
		destino=Vector2(fase.dados.largura*16,fase.dados.altura*16)
		escala=minf((tela.x-40)/(fase.dados.largura*32.0),(tela.y-104)/(fase.dados.altura*32.0))
	else:
		var a: Vector2=fase.lucas.global_position-Vector2(0,16*fase.lucas.altura_nivel)
		var b: Vector2=fase.otto.global_position-Vector2(0,16*fase.otto.altura_nivel)
		destino=(a+b)*0.5
		var distancia: Vector2=(a-b).abs()+Vector2(260,240)
		escala=clampf(minf((tela.x-60)/distancia.x,(tela.y-110)/distancia.y),0.27,0.9)
	if not inicializada:
		global_position=destino
		zoom=Vector2.ONE*escala
		inicializada=true
	else:
		global_position=global_position.lerp(destino,minf(1,delta*7))
		zoom=zoom.lerp(Vector2.ONE*escala,minf(1,delta*5))
