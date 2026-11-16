extends SceneTree
## Corrige somente recursos visuais, preservando geometria e IDs das cenas.
const ARTE = preload("res://recursos/arte_objetos_puzzle.gd")

func _initialize() -> void:
	call_deferred("executar")

func executar() -> void:
	DirAccess.make_dir_recursive_absolute("res://backups/recortes")
	for fase in [1,2,4]:
		var caminho := "res://cenas/areas/puzzle_%02d.tscn" % fase
		var cena: PackedScene = load(caminho)
		var raiz := cena.instantiate()
		var corrigidos := 0
		for objeto in raiz.get_node("Objetos").get_children():
			objeto.y_sort_enabled = false
			var tipo := str(objeto.name).get_slice("_",0).to_lower()
			for filho in objeto.get_children():
				if filho is Sprite2D:
					ARTE.aplicar(filho,tipo)
					corrigidos += 1
		raiz.get_node("MecanismoNico/Imagem").texture = ARTE.trava()
		for filho in raiz.get_children():
			if filho is Sprite2D and filho.texture is AtlasTexture and filho.texture.atlas.resource_path == ARTE.OBJETOS.resource_path and filho.texture.region == Rect2(16,80,16,32):
				raiz.remove_child(filho)
				filho.free()
		if raiz.has_node("Espelho"):
			var espelho := raiz.get_node("Espelho")
			for filho in espelho.get_children():
				if filho is Sprite2D or filho is NinePatchRect:
					espelho.remove_child(filho)
					filho.free()
			var superficie := ARTE.espelho()
			espelho.add_child(superficie)
			superficie.owner = raiz
			for filho in superficie.get_children():
				filho.owner = raiz
		var backup := "res://backups/recortes/puzzle_%02d_%d.tscn" % [fase,Time.get_ticks_usec()]
		assert(DirAccess.copy_absolute(caminho,backup) == OK)
		assert(cena.pack(raiz) == OK)
		assert(ResourceSaver.save(cena,caminho) == OK)
		raiz.free()
		print("RECORTES: fase %d, %d objetos completos, trava e braseiros corrigidos" % [fase,corrigidos])
	quit()
