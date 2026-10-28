extends SceneTree
const NOMES: Array[String] = ["01_jardim","02_galeria","03_oficina","04_santuario"]
const TEMA_UI=preload("res://scripts/visual/tema_pixel.gd")
const PACOTE: String = "res://assets/mapa/CRAFTPIX_DUNGEON/"
var tiles: TileSet
var backup: String
var texturas: Dictionary={}
func _initialize() -> void: call_deferred("construir")
func guardar(p: String) -> void:
	if FileAccess.file_exists(p):
		var destino: String=backup+"/"+p.trim_prefix("res://")
		DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
		DirAccess.copy_absolute(p,destino)
func construir() -> void:
	backup="res://backups/dungeon_"+str(Time.get_unix_time_from_system()).replace(".","_")
	for pasta in ["res://cenas/fases","res://recursos/fases","res://recursos/visual"]: DirAccess.make_dir_recursive_absolute(pasta)
	tiles=TileSet.new()
	tiles.tile_size=Vector2i(16,16)
	var atlas: TileSetAtlasSource=TileSetAtlasSource.new()
	atlas.texture=load(PACOTE+"walls_floor.png")
	atlas.texture_region_size=Vector2i(16,16)
	for y in range(29):
		for x in range(17): atlas.create_tile(Vector2i(x,y))
	tiles.add_source(atlas,0)
	guardar("res://recursos/fases/tileset_cross.tres")
	ResourceSaver.save(tiles,"res://recursos/fases/tileset_cross.tres")
	tiles.take_over_path("res://recursos/fases/tileset_cross.tres")
	for i in range(4): _fase(i)
	print("DUNGEON_BUILD_OK: quatro mapas conectados com CraftPix, agua e luzes.")
	quit()
func filho(raiz: Node,pai: Node,n: Node,nome: String) -> Node:
	n.name=nome
	pai.add_child(n)
	n.owner=raiz
	return n
func camada(raiz: Node2D,nome: String,z: int) -> TileMapLayer:
	var n: TileMapLayer=TileMapLayer.new()
	filho(raiz,raiz,n,nome)
	n.tile_set=tiles
	n.scale=Vector2(2,2)
	n.position.y=-16*z
	n.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	return n
func recorte(nome: String,r: Rect2) -> AtlasTexture:
	if not texturas.has(nome): texturas[nome]=load(PACOTE+nome+".png")
	var t: AtlasTexture=AtlasTexture.new()
	t.atlas=texturas[nome]
	t.region=r
	return t
func sprite(raiz: Node,pai: Node,nome: String,folha: String,r: Rect2,p: Vector2,escala: Vector2=Vector2(2,2)) -> Sprite2D:
	var n: Sprite2D=Sprite2D.new()
	n.texture=recorte(folha,r)
	n.position=p
	n.scale=escala
	filho(raiz,pai,n,nome)
	return n
func molhado(d: Dictionary,c: Vector2i) -> bool:
	for r in d.agua:
		if Rect2i(r[0],r[1],r[2],r[3]).has_point(c): return true
	return false
func _fase(i: int) -> void:
	var caminho_dados: String="res://recursos/fases/"+NOMES[i]+".json"
	var dados: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(caminho_dados))
	var raiz: Node2D=Node2D.new()
	raiz.name="Fase"+str(i+1)
	raiz.set_script(load("res://scripts/fases/fase.gd"))
	raiz.set("arquivo_dados",caminho_dados)
	raiz.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var agua: Node2D=Node2D.new()
	agua.set_script(load("res://scripts/visual/agua_cenario.gd"))
	agua.set("arquivo_dados",caminho_dados)
	filho(raiz,raiz,agua,"CanaisDeAgua")
	var pisos: Array[TileMapLayer]=[]
	for h in range(3): pisos.append(camada(raiz,"SoloZ"+str(h),h))
	var paredes: TileMapLayer=camada(raiz,"ParedesDePedra",0)
	var frentes: TileMapLayer=camada(raiz,"FrentesEBeirais",0)
	var grade: Dictionary={}
	for c in dados.chao: grade[Vector2i(c[0],c[1])]=int(c[2])
	for cel in dados.chao:
		var c: Vector2i=Vector2i(cel[0],cel[1])
		var h: int=int(cel[2])
		var norte: bool=int(grade.get(c+Vector2i.UP,-1))!=h
		var sul: bool=int(grade.get(c+Vector2i.DOWN,-1))!=h
		var oeste: bool=int(grade.get(c+Vector2i.LEFT,-1))!=h
		var leste: bool=int(grade.get(c+Vector2i.RIGHT,-1))!=h
		var tile: Vector2i=Vector2i(2,8)
		if norte: tile=Vector2i(2,7)
		if sul: tile=Vector2i(2,9)
		if oeste: tile=Vector2i(1,8)
		if leste: tile=Vector2i(3,8)
		if norte and oeste: tile=Vector2i(1,7)
		elif norte and leste: tile=Vector2i(3,7)
		elif sul and oeste: tile=Vector2i(1,9)
		elif sul and leste: tile=Vector2i(3,9)
		if not norte and not sul and not oeste and not leste and absi(hash(str(c.x)+":"+str(c.y)+":"+str(i)))%8==0:
			tile=Vector2i(7+absi(c.x+c.y)%2,13)
		pisos[h].set_cell(c,0,tile)
		pisos[h].modulate=[Color(0.94,1.0,0.95),Color(0.92,0.97,1.03),Color(1.03,0.99,0.94),Color(0.98,0.96,1.04)][i]
		if h==0:
			if not grade.has(c+Vector2i.UP) and not molhado(dados,c+Vector2i.UP):
				paredes.set_cell(c+Vector2i(0,-1),0,Vector2i(6,2))
				paredes.set_cell(c+Vector2i(0,-2),0,Vector2i(6,1))
			if not grade.has(c+Vector2i.LEFT) and not molhado(dados,c+Vector2i.LEFT): paredes.set_cell(c+Vector2i.LEFT,0,Vector2i(1,2))
			if not grade.has(c+Vector2i.RIGHT) and not molhado(dados,c+Vector2i.RIGHT): paredes.set_cell(c+Vector2i.RIGHT,0,Vector2i(3,2))
			if not grade.has(c+Vector2i.DOWN) and not molhado(dados,c+Vector2i.DOWN):
				frentes.set_cell(c+Vector2i.DOWN,0,Vector2i(6,3))
	var bordas: Node2D=filho(raiz,raiz,Node2D.new(),"Bordas")
	for j in range(dados.paredes.size()):
		var r: Array=dados.paredes[j]
		var corpo: StaticBody2D=StaticBody2D.new()
		corpo.position=Vector2((r[0]+0.5)*32,(r[1]+0.5)*32)
		corpo.collision_layer=1
		corpo.collision_mask=6
		corpo.set_meta("altura",-99)
		filho(raiz,bordas,corpo,"Parede"+str(j))
		var col: CollisionShape2D=CollisionShape2D.new()
		var forma: RectangleShape2D=RectangleShape2D.new()
		forma.size=Vector2(32,32)
		col.shape=forma
		filho(raiz,corpo,col,"Colisao")
	var detalhes: Node2D=filho(raiz,raiz,Node2D.new(),"ArquiteturaEDecoracao")
	for cel in dados.chao:
		var h: int=cel[2]
		if h>0 and int(grade.get(Vector2i(cel[0],cel[1]+1),-1))<h:
			sprite(raiz,detalhes,"Face"+str(cel[0])+"_"+str(cel[1]),"walls_floor",Rect2(96,32,16,16),Vector2(cel[0]*32+16,cel[1]*32+32-8*h),Vector2(2,h)).modulate=Color("8d95ac")
	for ponto in dados.rampas:
		var h: int=int(grade.get(Vector2i(ponto[0],ponto[1]),1))
		sprite(raiz,detalhes,"Escada"+str(ponto),"walls_floor",Rect2(144,176,16,16),Vector2(ponto[0]*32+16,ponto[1]*32+16-16*h))
	var modulacao: CanvasModulate=CanvasModulate.new()
	modulacao.color=Color(0.78,0.81,0.9)
	filho(raiz,raiz,modulacao,"LuzAmbiente")
	var gradiente: Gradient=Gradient.new()
	gradiente.set_color(0,Color(1,0.75,0.38,0.9))
	gradiente.set_color(1,Color(1,0.6,0.25,0))
	var luztext: GradientTexture2D=GradientTexture2D.new()
	luztext.width=256
	luztext.height=256
	luztext.fill=GradientTexture2D.FILL_RADIAL
	luztext.fill_from=Vector2(0.5,0.5)
	luztext.fill_to=Vector2(1,0.5)
	luztext.gradient=gradiente
	var usados_decoracao: Array[Vector2i]=[]
	for j in range(dados.salas.size()):
		var r: Array=dados.salas[j]
		for x in [r[0]+2,r[0]+r[2]-3]:
			var apoio: Vector2i=Vector2i(x,r[1]-1)
			if grade.has(apoio) or molhado(dados,apoio): continue
			var fogo: AnimatedSprite2D=AnimatedSprite2D.new()
			var quadros: SpriteFrames=SpriteFrames.new()
			quadros.set_animation_speed("default",8)
			for q in range(6): quadros.add_frame("default",recorte("fire_animation",Rect2(0,q*48,32,48)))
			fogo.sprite_frames=quadros
			fogo.autoplay="default"
			fogo.position=Vector2(x*32+16,r[1]*32-12)
			fogo.scale=Vector2(1.2,1.2)
			filho(raiz,detalhes,fogo,"Tocha"+str(j)+"_"+str(x))
			var luz: PointLight2D=PointLight2D.new()
			luz.texture=luztext
			luz.energy=0.7
			luz.position=fogo.position+Vector2(0,16)
			filho(raiz,detalhes,luz,"Luz"+str(j)+"_"+str(x))
		# Reentrancias e grupos de urnas/tesouros junto as paredes.
		for ax in [int(r[0]+r[2]/2),r[0]+1,r[0]+r[2]-2]:
			var apoio: Vector2i=Vector2i(ax,r[1]-1)
			if grade.has(apoio) or grade.has(apoio+Vector2i.RIGHT) or molhado(dados,apoio) or molhado(dados,apoio+Vector2i.RIGHT): continue
			sprite(raiz,detalhes,"Arco"+str(j),"walls_floor",Rect2(0,416,32,48),Vector2((ax+0.5)*32,r[1]*32-16),Vector2(1.3,1.3))
			break
		var candidatos: Array[Vector2i]=[Vector2i(r[0]+1,r[1]+1),Vector2i(r[0]+r[2]-2,r[1]+1),Vector2i(r[0]+1,r[1]+r[3]-2),Vector2i(r[0]+r[2]-2,r[1]+r[3]-2),Vector2i(r[0]+r[2]/2,r[1]+1)]
		for item in range(2):
			for c: Vector2i in candidatos:
				if not decoracao_livre(dados,c,grade,usados_decoracao): continue
				usados_decoracao.append(c)
				var h: int=int(grade[c])
				var centro: Vector2=Vector2(c)*32+Vector2(16,16-16*h)
				var sombra: Polygon2D=Polygon2D.new()
				sombra.polygon=PackedVector2Array([Vector2(-12,-4),Vector2(10,-4),Vector2(14,0),Vector2(10,4),Vector2(-10,4),Vector2(-14,0)])
				sombra.position=centro
				sombra.color=Color(0.06,0.08,0.13,0.3)
				filho(raiz,detalhes,sombra,"SombraItem"+str(j)+"_"+str(item))
				var regiao: Rect2=Rect2(144,16,32,16) if item==0 else Rect2(208,80,16,16)
				var decor: Sprite2D=sprite(raiz,detalhes,("Tesouro" if item==0 else "Urna")+str(j),"Objects",regiao,centro-Vector2(0,16),Vector2(2,2))
				decor.set_meta("celula",c)
				decor.set_meta("altura",h)
				break
	var ambiente: Node2D=Node2D.new()
	ambiente.set_script(load("res://scripts/visual/ambiente.gd"))
	ambiente.set("indice",i)
	filho(raiz,raiz,ambiente,"Ambiente")
	var objetos: Node2D = filho(raiz, raiz, Node2D.new(), "Objetos")
	for config in dados["objetos"]:
		var objeto: StaticBody2D = StaticBody2D.new()
		objeto.set_script(load("res://scripts/fases/objeto_puzzle.gd"))
		objeto.set("config", config)
		filho(raiz, objetos, objeto, config["id"])
		objeto.position = Vector2(config["x"] * 32 + 16, config["y"] * 32 + 16)
		objeto.rotation_degrees = float(config.get("rot", 0))
		var forma: RectangleShape2D = RectangleShape2D.new()
		forma.size = Vector2(28, 22) if config["tipo"] != "espelho" else Vector2(58, 10)
		var col: CollisionShape2D = CollisionShape2D.new()
		col.shape = forma
		col.position = Vector2(0, -8 if config["tipo"] != "espelho" else -4)
		filho(raiz, objeto, col, "Colisao")
		if config["tipo"] in ["planta","barril"]:
			var area: Area2D = Area2D.new()
			area.collision_layer = 16
			area.collision_mask = 0
			filho(raiz, objeto, area, "AreaDano")
			var hurt: CollisionShape2D = CollisionShape2D.new()
			hurt.shape = forma
			hurt.position = Vector2(0, -8)
			filho(raiz, area, hurt, "Colisao")
		if config["tipo"] in ["barril","caixa"]:
			var imagem: Sprite2D = Sprite2D.new()
			var regiao: Rect2=Rect2(192,80,16,16) if config["tipo"] == "barril" else Rect2(80,80,16,16)
			imagem.texture = recorte("Objects",regiao)
			imagem.scale = Vector2(2,2)
			imagem.position.y = -regiao.size.y - 16 * int(config.get("z",0))
			filho(raiz, objeto, imagem, "Sprite")
		if config["tipo"] == "estacao":
			var label: Label = Label.new()
			label.position = Vector2(-40,-46)
			label.size.x = 80
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_override("font",TEMA_UI.fonte())
			label.add_theme_font_size_override("font_size",8)
			label.add_theme_color_override("font_color",Color("d8e1de"))
			label.add_theme_color_override("font_shadow_color",Color("111b2b"))
			label.add_theme_constant_override("shadow_offset_y",1)
			label.text = str(config["elemento"]).to_upper()
			filho(raiz, objeto, label, "Legenda")
	var plataformas: Node2D = filho(raiz, raiz, Node2D.new(), "Plataformas")
	for j in range(dados["plataformas"].size()):
		var config: Dictionary = dados["plataformas"][j]
		var p: Node2D = Node2D.new()
		p.set_script(load("res://scripts/fases/plataforma_movel.gd"))
		p.set("amplitude",Vector2(config["amp"][0],config["amp"][1]))
		p.set("periodo",float(config["periodo"]))
		p.set("altura",int(config["z"]))
		p.position = Vector2(config["x"] * 32 + 16, config["y"] * 32 + 16)
		filho(raiz, plataformas, p, "Plataforma" + str(j))
	var chars: Node2D = filho(raiz, raiz, Node2D.new(), "Personagens")
	chars.y_sort_enabled = true
	for j in range(2):
		var ator: CharacterBody2D = load("res://cenas/personagens/" + ("guerreiro" if j == 0 else "robo") + ".tscn").instantiate()
		filho(raiz, chars, ator, "Guerreiro" if j == 0 else "Robo")
		ator.position = Vector2(dados["spawns"][j][0] * 32 + 16, dados["spawns"][j][1] * 32 + 16)
		_sombra(raiz, ator)
	for j in range(dados["inimigos"].size()):
		var config: Dictionary = dados["inimigos"][j]
		var arquivo: String = "cavaleiro_azul" if config["tipo"] == "guardiao" else config["tipo"]
		var ator: CharacterBody2D = load("res://cenas/personagens/" + arquivo + ".tscn").instantiate()
		if config["tipo"] == "guardiao":
			ator.set_script(load("res://scripts/fases/guardiao.gd"))
			ator.set("nome_personagem","Guardião da Provação")
			ator.set("vida_maxima",260)
			ator.set("velocidade",58.0)
			ator.set("alcance_ataque",38.0)
			ator.get_node("Visual").scale = Vector2(1.4,1.4)
			ator.get_node("ArmaduraCaida").scale = Vector2(1.4,1.4)
		filho(raiz, chars, ator, "Guardiao" if config["tipo"] == "guardiao" else "Inimigo" + str(j))
		ator.position = Vector2(config["x"] * 32 + 16,config["y"] * 32 + 16)
		_sombra(raiz, ator)
	var npcs: Node2D = filho(raiz, raiz, Node2D.new(), "Exploradores")
	for j in range(dados["npcs"].size()):
		var npc: Node2D = Node2D.new()
		npc.set_script(load("res://scripts/fases/explorador.gd"))
		var pontos: PackedVector2Array = PackedVector2Array()
		for p in dados["npcs"][j]:
			pontos.append(Vector2(p[0]*32+16,p[1]*32+16))
		npc.set("caminho",pontos)
		npc.position = pontos[0]
		filho(raiz,npcs,npc,"Explorador"+str(j))
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = load("res://assets/mapa/0x72_16x16DungeonTileset.v5/0x72_16x16DungeonTileset.v5/items/npc_merchant.png")
		sprite.scale = Vector2(2,2)
		filho(raiz,npc,sprite,"Sprite")

	var camera: Camera2D = Camera2D.new()
	camera.set_script(load("res://scripts/visual/camera_coop.gd"))
	camera.position=Vector2(dados.largura*16,dados.altura*16)
	filho(raiz,raiz,camera,"CameraCompartilhada")
	var cena: PackedScene = PackedScene.new()
	if cena.pack(raiz) != OK: push_error("Falha ao salvar fase")
	var destino: String="res://cenas/fases/"+NOMES[i]+".tscn"
	guardar(destino)
	ResourceSaver.save(cena,destino)
	raiz.free()

func _sombra(raiz: Node, ator: CharacterBody2D) -> void:
	var sombra: Polygon2D = Polygon2D.new()
	var pontos: PackedVector2Array = PackedVector2Array()
	for i in range(12):
		pontos.append(Vector2(cos(float(i)*TAU/12)*9,sin(float(i)*TAU/12)*4))
	sombra.polygon = pontos
	sombra.color = Color(0.03,0.05,0.08,0.28)
	filho(raiz,ator,sombra,"Sombra")
	ator.move_child(sombra,0)

func decoracao_livre(dados: Dictionary,c: Vector2i,grade: Dictionary,usados: Array[Vector2i]) -> bool:
	if not grade.has(c): return false
	for usado: Vector2i in usados:
		if Vector2(c).distance_to(Vector2(usado))<2.0: return false
	for obj in dados.objetos:
		if Vector2(c).distance_to(Vector2(obj.x,obj.y))<2.0: return false
	for pos in dados.spawns:
		if Vector2(c).distance_to(Vector2(pos[0],pos[1]))<2.0: return false
	for obj in dados.inimigos:
		if Vector2(c).distance_to(Vector2(obj.x,obj.y))<2.0: return false
	for caminho in dados.npcs:
		for pos in caminho:
			if Vector2(c).distance_to(Vector2(pos[0],pos[1]))<1.5: return false
	for pos in dados.rampas:
		if Vector2(c).distance_to(Vector2(pos[0],pos[1]))<2.0: return false
	return true
