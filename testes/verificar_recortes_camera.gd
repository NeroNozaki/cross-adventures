extends SceneTree
const ARTE = preload("res://recursos/arte_objetos_puzzle.gd")
const MAPAS = preload("res://recursos/mapas_puzzle.gd")
var total := 0
var erros := 0

func _initialize() -> void:
	call_deferred("executar")

func conferir(condicao: bool, mensagem: String) -> void:
	total += 1
	if not condicao:
		erros += 1
		push_error(mensagem)

func executar() -> void:
	for fase in [1,2,4]:
		var cena: PackedScene = load("res://cenas/areas/puzzle_%02d.tscn" % fase)
		var sala := cena.instantiate()
		var dados: Dictionary = MAPAS.FASES[fase]
		var objetos := sala.get_node("Objetos").get_children()
		conferir(objetos.size() == dados.props.size(), "Quantidade de objetos preservada na fase %d" % fase)
		for i in objetos.size():
			var objeto: Node2D = objetos[i]
			var tipo := str(objeto.name).get_slice("_",0).to_lower()
			var sprite: Sprite2D
			for filho in objeto.get_children():
				if filho is Sprite2D:
					sprite = filho
			var atlas := sprite.texture as AtlasTexture
			conferir(atlas.region == ARTE.RECORTES[tipo], "Peça inteira: " + str(objeto.name))
			conferir(atlas.filter_clip, "Filtro não vaza peças vizinhas")
			conferir(not objeto.y_sort_enabled, "Profundidade pelo pé, não pelo centro do sprite")
			var regiao := atlas.get_image().get_used_rect()
			conferir(regiao.has_area(), "Recorte não vazio")
			var pe := sprite.position.y + (regiao.end.y - atlas.get_height() * 0.5) * sprite.scale.y
			conferir(is_equal_approx(pe,3.0), "Pixels visíveis apoiados no chão")
			var posicao := Vector2(dados.props[i][0],dados.props[i][1]) * 24 + Vector2(12,12)
			conferir(objeto.position == posicao, "Decoração não foi movida")
			conferir(objeto.get_node("Apoio/shape").shape.size == Vector2(16,8), "Colisão original preservada")
		conferir(sala.get_node("MecanismoNico/Imagem").texture.region == Rect2(144,112,16,16), "Trava usa alavanca completa, não armadura")
		for filho in sala.get_children():
			if filho is Sprite2D and filho.texture is AtlasTexture:
				conferir(filho.texture.region != Rect2(16,80,16,32), "Sem suporte de braseiro cortado")
		if fase == 4:
			conferir(sala.get_node("Espelho/MolduraEspelho") is NinePatchRect, "Espelho usa moldura inteira")
			conferir(sala.get_node("Espelho/shape").shape.size == Vector2(48,8), "Normal e corpo do espelho preservados")
		sala.free()
	var historia = root.get_node("HistoriaDupla")
	for nome in ["puzzle_01", "puzzle_02", "area_3", "puzzle_04"]:
		change_scene_to_file("res://cenas/areas/%s.tscn" % nome)
		await process_frame
		await process_frame
		if historia.ativa:
			historia.finalizar()
		paused = false
		if nome == "area_3":
			conferir(current_scene.get_node("Personagens/Camera2D").zoom == Vector2.ONE * 0.62, "Fase 3 com enquadramento mais aberto")
		else:
			current_scene._atualizar_camera(10.0)
			var camera: Camera2D = current_scene.get_node("Camera")
			conferir(camera.zoom.x <= 1.05 and camera.zoom.x >= 0.55, "Câmera adaptativa mais distante")
			conferir(camera.zoom.x < 1.25, "Zoom não volta ao limite antigo")
			var tela := root.get_visible_rect()
			camera.force_update_scroll()
			for heroi in [current_scene.nico,current_scene.otto]:
				conferir(tela.has_point(heroi.get_global_transform_with_canvas().origin), "Dupla permanece visível")
	current_scene.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("RECORTES_CAMERA: %d verificações, %d falhas" % [total,erros])
	quit(0 if erros == 0 else 1)
