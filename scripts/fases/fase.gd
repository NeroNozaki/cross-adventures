extends Node2D
## As quatro fases usam dados e TileMapLayers independentes por altura.
@export_file("*.json") var arquivo_dados: String
var dados: Dictionary = {}
var sinais: Dictionary = {}
var grade: Dictionary = {}
var rampas: Array[Vector2i] = []
var atores: Array = []
var lucas: CharacterBody2D
var otto: CharacterBody2D
var saida: Node2D
var aviso: String = ""
var aviso_t: float = 0.0
var concluida: bool = false
var mortes: Dictionary = {}
var hud: Label
var mensagem: Label
var ajuda: PanelContainer
const TEMA_UI=preload("res://scripts/visual/tema_pixel.gd")
const TAM: float = 32.0
const CORES: Dictionary = {"normal": Color("#75e5ef"), "fogo": Color("#ff9a61"), "gelo": Color("#83e2ff"), "choque": Color("#cfabff"), "onda": Color("#6af3c0")}

func _enter_tree() -> void:
	add_to_group("fase_atual")

func _ready() -> void:
	dados = JSON.parse_string(FileAccess.get_file_as_string(arquivo_dados))
	for item in dados["chao"]:
		grade[Vector2i(item[0], item[1])] = int(item[2])
	for item in dados.get("rampas", []):
		rampas.append(Vector2i(item[0], item[1]))
	lucas = $Personagens/Guerreiro
	otto = $Personagens/Robo
	for ator in $Personagens.get_children():
		atores.append(ator)
		ator.nome_label.add_theme_font_override("font",TEMA_UI.fonte())
		ator.nome_label.add_theme_font_size_override("font_size",8)
		ator.altura_nivel = int(grade.get(celula(ator.global_position), 0))
	saida = $Objetos.get_node("Saida")
	_criar_interface()
	avisar(str(dados["introducao"]), 9.0)

func celula(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TAM), floori(p.y / TAM))

func altura_em(p: Vector2) -> int:
	for plataforma in $Plataformas.get_children():
		if plataforma.contem(p):
			return plataforma.altura
	var c: Vector2i = celula(p)
	for ponte in dados.get("pontes", []):
		var r: Rect2 = Rect2(ponte[0] * TAM, ponte[1] * TAM, ponte[2] * TAM, ponte[3] * TAM)
		if r.has_point(p) and sinais.get(str(ponte[5]), false):
			return int(ponte[4])
	return int(grade.get(c, -1))

func mover_personagem(ator: CharacterBody2D, delta: float) -> void:
	if ator.pulando:
		ator.tempo_salto += delta
		var p: float = clampf(ator.tempo_salto / 0.42, 0.0, 1.0)
		ator.global_position = ator.salto_origem.lerp(ator.salto_destino, smoothstep(0.0, 1.0, p))
		ator.altura_salto = sin(p * PI) * 24.0
		if p >= 1.0:
			ator.pulando = false
			ator.altura_salto = 0.0
		_atualizar_visual(ator)
		return
	var proximo: Vector2 = ator.global_position + ator.velocity * delta
	var h: int = altura_em(proximo)
	var rampa: bool = celula(proximo) in rampas or celula(ator.global_position) in rampas
	if h < 0 or (h != ator.altura_nivel and not rampa):
		var x: Vector2 = ator.global_position + Vector2(ator.velocity.x * delta, 0)
		var y: Vector2 = ator.global_position + Vector2(0, ator.velocity.y * delta)
		if altura_em(x) != ator.altura_nivel:
			ator.velocity.x = 0
		if altura_em(y) != ator.altura_nivel:
			ator.velocity.y = 0
	elif h != ator.altura_nivel:
		ator.altura_nivel = h
	ator.move_and_slide()
	_atualizar_visual(ator)

func _atualizar_visual(ator: CharacterBody2D) -> void:
	var elevacao: float = -16.0 * ator.altura_nivel - ator.altura_salto
	for nome in ["Visual", "Sombra", "Nome", "BarraVida", "EfeitosCombate", "Mira360", "ArmaduraCaida"]:
		if not ator.has_node(nome):
			continue
		var no: CanvasItem = ator.get_node(nome)
		if not no.has_meta("base_y"):
			no.set_meta("base_y", no.position.y)
		no.position.y = float(no.get_meta("base_y")) + (-16.0 * ator.altura_nivel if nome == "Sombra" else elevacao)

func tentar_salto(ator: CharacterBody2D, vetor: Vector2 = Vector2.ZERO) -> bool:
	if ator.esta_morto or ator.pulando or ator.atacando or ator.tempo_dano > 0.0:
		return false
	var dir: Vector2 = vetor.normalized() if vetor.length_squared() > 0.01 else ator.frente
	var destino: Vector2 = ator.global_position + dir * 64.0
	if altura_em(destino) != ator.altura_nivel:
		avisar("Salte para uma superficie da mesma altura.")
		return false
	var consulta: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ator.global_position, destino, 1)
	consulta.exclude = [ator.get_rid()]
	if not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty():
		return false
	var forma: CircleShape2D = CircleShape2D.new()
	forma.radius = 9
	var q: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	q.shape = forma
	q.transform = Transform2D(0, destino)
	q.collision_mask = 1
	if not get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty():
		return false
	ator.definir_defesa(false)
	if ator.has_method("cancelar_carga"):
		ator.cancelar_carga()
	ator.pulando = true
	ator.tempo_salto = 0
	ator.salto_origem = ator.global_position
	ator.salto_destino = destino
	return true

func interagir(ator: CharacterBody2D) -> bool:
	var melhor: Node2D
	var distancia: float = 54.0
	for obj in $Objetos.get_children():
		var d: float = ator.global_position.distance_to(obj.global_position)
		if d < distancia and obj.tipo() in ["caixa", "gelo", "placa_texto", "estacao"]:
			distancia = d
			melhor = obj
	return melhor.interagir(ator) if melhor != null else false

func pode_colocar_caixa(p: Vector2, z: int, ignorar: Node) -> bool:
	if altura_em(p) != z:
		return false
	for obj in $Objetos.get_children():
		if obj != ignorar and obj.collision_layer != 0 and p.distance_to(obj.global_position) < 25:
			return false
	for ator in atores:
		if not ator.esta_morto and ator.altura_nivel == z and p.distance_to(ator.global_position) < 18:
			return false
	var q: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(ignorar.global_position, p, 1)
	q.exclude = [ignorar.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()

func sinalizar(chave: String, valor: bool) -> void:
	if sinais.get(chave, false) == valor:
		return
	sinais[chave] = valor
	if valor and chave not in ["placa_a", "peso"]:
		avisar("Mecanismo ativado: " + chave.replace("_", " ") + ".")
	queue_redraw()

func condicao_receptor(config: Dictionary) -> bool:
	for condicao in config.get("depende", []):
		if not sinais.get(str(condicao), false):
			avisar("Lucas precisa manter a placa pressionada.")
			return false
	return true

func condicoes(lista: Array) -> bool:
	for id in lista:
		if not sinais.get(str(id), false):
			return false
	return true

func _physics_process(delta: float) -> void:
	if concluida:
		return
	for plataforma in $Plataformas.get_children():
		plataforma.avancar(delta, atores)
	for obj in $Objetos.get_children():
		if obj.tipo() == "placa":
			var peso: bool = false
			if not obj.config.get("somente_caixa", false):
				for ator in [lucas, otto]:
					if not ator.esta_morto and not ator.pulando and (not obj.config.has("personagem") or ator.nome_personagem == obj.config.personagem) and ator.altura_nivel == obj.altura_nivel and ator.global_position.distance_to(obj.global_position) < 18:
						peso = true
			for caixa in $Objetos.get_children():
				if caixa.tipo() in ["caixa", "gelo"] and caixa.altura_nivel == obj.altura_nivel and caixa.global_position.distance_to(obj.global_position) < 12:
					peso = true
			obj.definir_ativo(peso)
			sinalizar(str(obj.config.get("sinal", obj.name)), peso)
	for id in dados.get("regras", {}):
		if condicoes(dados["regras"][id]):
			sinalizar(id, true)
	for obj in $Objetos.get_children():
		if obj.tipo() == "porta":
			obj.definir_ativo(condicoes(obj.config.get("depende", [])))
	var todos_derrotados: bool = true
	for ator in atores:
		if ator.equipe == 1 and not ator.esta_morto:
			todos_derrotados = false
		if ator.has_method("_draw") and ator.get_script().resource_path.ends_with("guardiao.gd"):
			ator.protegido = not condicoes(dados.get("selos", []))
	var pronto: bool = condicoes(dados.get("objetivos", [])) and todos_derrotados
	saida.definir_ativo(pronto)
	for ator in atores:
		for outro in atores:
			if ator != outro:
				if ator.altura_nivel != outro.altura_nivel or ator.pulando or outro.pulando:
					ator.add_collision_exception_with(outro)
				else:
					ator.remove_collision_exception_with(outro)
		for obj in $Objetos.get_children():
			if obj.altura_nivel != ator.altura_nivel:
				ator.add_collision_exception_with(obj)
			else:
				ator.remove_collision_exception_with(obj)
	for heroi in [lucas, otto]:
		if heroi.esta_morto:
			mortes[heroi.name] = float(mortes.get(heroi.name, 0)) + delta
			if mortes[heroi.name] > 3.0:
				restaurar(heroi)
	if pronto and not lucas.esta_morto and not otto.esta_morto and not lucas.pulando and not otto.pulando:
		if lucas.altura_nivel == saida.altura_nivel and otto.altura_nivel == saida.altura_nivel and lucas.global_position.distance_to(saida.global_position) < 45 and otto.global_position.distance_to(saida.global_position) < 45:
			terminar()
			return
	aviso_t = maxf(0, aviso_t - delta)
	mensagem.text = aviso if aviso_t > 0 else ("Portal aberto: reunam Lucas e Otto na saida." if pronto else "")
	hud.text = "%d/4  %s    |    Lucas %d  Otto %d\n%s\nF/P: saltos  E/I: interagir  C: elemento [%s]  Tab: travar mira  F1: ajuda" % [dados["numero"], dados["nome"], lucas.vida_atual, otto.vida_atual, dados["objetivo"], otto.elemento.to_upper()]
	queue_redraw()

func restaurar(heroi: CharacterBody2D) -> void:
	mortes[heroi.name] = 0.0
	heroi.esta_morto = false
	heroi.vida_atual = heroi.vida_maxima
	heroi.audio.morto = false
	heroi.pulando = false
	heroi.altura_salto = 0
	heroi.tempo_salto = 0
	heroi.tempo_dano = 0
	heroi.impulso = Vector2.ZERO
	heroi.invulnerabilidade.stop()
	heroi.efeitos.parar()
	heroi.atacando = false
	heroi.preparo.stop()
	heroi.recarga.stop()
	heroi.collision_layer = 2
	heroi.collision_mask = 5
	heroi.area_dano.collision_layer = 8
	heroi.barra_vida.value = heroi.vida_atual
	heroi.barra_vida.show()
	heroi.nome_label.modulate = Color.WHITE
	heroi.animacao.modulate = Color.WHITE
	heroi.animacao.show()
	var spawn: Array = dados["spawns"][0 if heroi == lucas else 1]
	heroi.position = Vector2(spawn[0] * TAM + 16, spawn[1] * TAM + 16)
	heroi.altura_nivel = int(grade.get(celula(heroi.position), 0))
	avisar("Companheiro recuperado no inicio da sala.")

func terminar() -> void:
	if concluida:
		return
	concluida = true
	if dados["numero"] < 4:
		get_node("/root/FluxoTela").call_deferred("trocar",str(dados["proxima"]))
	else:
		lucas.controlado = false
		otto.controlado = false
		aviso_t = 9999
		mensagem.text = "PROVACAO CONCLUIDA! Lucas e Otto conquistaram a Medalha da Equipe. R: jogar novamente."
		hud.text = "CROSS ADVENTURES  |  Juntos, voces conseguiram!\nA forca de Lucas e a engenhosidade de Otto completaram a Provacao do Heroi.\nR: voltar ao Jardim da Provacao"

func avisar(texto: String, tempo: float = 4.0) -> void:
	aviso = texto
	aviso_t = tempo

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reiniciar"):
		if concluida and dados["numero"] == 4:
			get_node("/root/FluxoTela").trocar("res://cenas/fases/01_jardim.tscn")
		else:
			get_node("/root/FluxoTela").trocar(scene_file_path)
	if event.is_action_pressed("alternar_audio"):
		var bus: int = AudioServer.get_bus_index("SFX")
		AudioServer.set_bus_mute(bus, not AudioServer.is_bus_mute(bus))
	if event.is_action_pressed("ajuda_fases"):
		ajuda.visible = not ajuda.visible
	if concluida:
		return
	if event.is_action_pressed("lucas_pular"):
		tentar_salto(lucas, Input.get_vector("guerreiro_esquerda", "guerreiro_direita", "guerreiro_cima", "guerreiro_baixo"))
	if event.is_action_pressed("otto_pular"):
		tentar_salto(otto, Input.get_vector("robo_esquerda", "robo_direita", "robo_cima", "robo_baixo"))
	if event.is_action_pressed("lucas_interagir"):
		interagir(lucas)
	if event.is_action_pressed("otto_interagir"):
		interagir(otto)
	if event.is_action_pressed("elemento_seguinte") and dados["numero"] >= 3:
		var tipos: Array[String] = ["normal", "fogo", "gelo", "choque", "onda"]
		otto.elemento = tipos[(tipos.find(otto.elemento) + 1) % tipos.size()]
	if event.is_action_pressed("travar_mira"):
		otto.mira.travada = not otto.mira.travada

func _criar_interface() -> void:
	var tela: CanvasLayer = CanvasLayer.new()
	tela.name = "Interface"
	add_child(tela)
	var gui: Control = Control.new()
	gui.set_script(load("res://scripts/visual/hud.gd"))
	gui.set("fase",self)
	tela.add_child(gui)
	hud=gui.estado_debug
	mensagem=gui.mensagem
	ajuda=gui.ajuda

const PISO_DUNGEON: Texture2D=preload("res://assets/mapa/CRAFTPIX_DUNGEON/walls_floor.png")
func _draw() -> void:
	if dados.is_empty(): return
	draw_rect(Rect2(-256,-256,dados.largura*32+512,dados.altura*32+512),Color(dados.fundo))
	for ponte in dados.pontes:
		if sinais.get(str(ponte[5]),false):
			for y in range(ponte[1],ponte[1]+ponte[3]):
				for x in range(ponte[0],ponte[0]+ponte[2]):
					draw_texture_rect_region(PISO_DUNGEON,Rect2(x*32,y*32-16*ponte[4],32,32),Rect2(32,128,16,16))

func direcao_ia(ator: CharacterBody2D,destino: Vector2) -> Vector2:
	# Segue corredores e escadas; nao tenta atravessar canais nem saltar vãos.
	var inicio: Vector2i=celula(ator.global_position)
	var fim: Vector2i=celula(destino)
	if inicio==fim: return ator.global_position.direction_to(destino)
	var cache: Dictionary=ator.get_meta("rota_cenario",{})
	var agora: int=Time.get_ticks_msec()
	if cache.get("fim",Vector2i(-999,-999))!=fim or agora>int(cache.get("ate",0)):
		var fila: Array[Vector2i]=[inicio]
		var pais: Dictionary={inicio:inicio}
		var bloqueios: Dictionary={}
		for r in dados.paredes: bloqueios[Vector2i(r[0],r[1])]=true
		for obj in $Objetos.get_children():
			if obj.collision_layer!=0 and obj.altura_nivel==ator.altura_nivel:
				bloqueios[celula(obj.global_position)]=true
		while not fila.is_empty() and not pais.has(fim):
			var c: Vector2i=fila.pop_front()
			var z: int=altura_em(Vector2(c)*32+Vector2(16,16))
			for dir in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
				var n: Vector2i=c+dir
				if pais.has(n) or bloqueios.has(n): continue
				var h: int=altura_em(Vector2(n)*32+Vector2(16,16))
				if h<0 or (h!=z and c not in rampas and n not in rampas): continue
				pais[n]=c
				fila.append(n)
		var caminho: Array[Vector2]=[]
		if pais.has(fim):
			var c: Vector2i=fim
			while c!=inicio:
				caminho.push_front(Vector2(c)*32+Vector2(16,16))
				c=pais[c]
		cache={"fim":fim,"ate":agora+450,"pontos":caminho}
		ator.set_meta("rota_cenario",cache)
	var pontos: Array=cache.get("pontos",[])
	while not pontos.is_empty() and ator.global_position.distance_to(pontos[0])<6: pontos.pop_front()
	if pontos.is_empty(): return Vector2.ZERO
	return ator.global_position.direction_to(pontos[0])
