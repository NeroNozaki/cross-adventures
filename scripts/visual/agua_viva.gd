extends Node2D
## Efeitos leves de superfície. Não cria corpos, áreas ou colisões de gameplay.
var agua: Node2D
var rng: RandomNumberGenerator=RandomNumberGenerator.new()
var celulas: Array[Vector2i]=[]
var gotas: Array[Dictionary]=[]
var ondas: Array[Dictionary]=[]
var peixes: Array[Dictionary]=[]
var espera: float=0.0
var tempo: float=0.0
const MAX_ONDAS: int=18
const MAX_GOTAS: int=4
const MAX_PEIXES: int=6
func _ready() -> void:
	agua=get_parent()
	rng.randomize()
	for c: Vector2i in agua.agua:
		if int(agua.profundidades.get(c,0))>=2: celulas.append(c)
	for i in range(MAX_PEIXES):
		var p: Vector2=ponto_livre()
		# Dois peixes próximos à entrada apresentam o ambiente vivo sem ocupar a ponte.
		if i<2:
			var origem: Vector2=Vector2(agua.dados.spawns[0][0]*32+16,agua.dados.spawns[0][1]*32+16)
			var menor: float=INF
			for c: Vector2i in celulas:
				var passagem: bool=false
				for ponte in agua.dados.pontes:
					if Rect2i(ponte[0],ponte[1],ponte[2],ponte[3]).has_point(c): passagem=true
				var centro: Vector2=Vector2(c)*32+Vector2(16,16)
				if not passagem and centro.distance_squared_to(origem)<menor:
					menor=centro.distance_squared_to(origem)
					p=centro+Vector2(-4 if i==0 else 4,0)
		if not p.is_finite(): break
		peixes.append({"p":p,"origem":p,"destino":p,"dir":Vector2.RIGHT,"t":0.0,"duracao":1.0,"espera":rng.randf_range(0.2,3.5),"cor":i%3,"rastro":0.0})
	for i in range(5):
		var p: Vector2=ponto_livre()
		if p.is_finite(): ondas.append({"p":p,"idade":rng.randf_range(0.0,1.0),"vida":2.2,"forca":0.22})
func molhado(p: Vector2) -> bool:
	var c: Vector2i=Vector2i(floori(p.x/32),floori(p.y/32))
	return agua.agua.has(c) and not agua.ponte_em(c)
func ponto_livre() -> Vector2:
	if celulas.is_empty(): return Vector2.INF
	for tentativa in range(24):
		var c: Vector2i=celulas[rng.randi_range(0,celulas.size()-1)]
		var p: Vector2=(Vector2(c)*32+Vector2(rng.randi_range(10,22),rng.randi_range(10,22))).snapped(Vector2(2,2))
		if molhado(p): return p
	return Vector2.INF
func trajeto_molhado(a: Vector2,b: Vector2) -> bool:
	var passos: int=maxi(1,ceili(a.distance_to(b)/6.0))
	for i in range(passos+1):
		if not molhado(a.lerp(b,float(i)/passos)): return false
	return true
func criar_onda(p: Vector2,forca: float=0.35) -> void:
	if ondas.size()>=MAX_ONDAS or not molhado(p): return
	ondas.append({"p":p,"idade":0.0,"vida":rng.randf_range(1.6,2.6),"forca":forca})
func avancar(delta: float) -> void:
	tempo+=delta
	espera-=delta
	if espera<=0:
		espera=rng.randf_range(0.45,1.4)
		var p: Vector2=ponto_livre()
		if p.is_finite() and gotas.size()<MAX_GOTAS: gotas.append({"p":p,"idade":0.0,"vida":rng.randf_range(0.25,0.4)})
	for gota in gotas:
		gota.idade+=delta
		if gota.idade>=gota.vida: criar_onda(gota.p,0.48)
	gotas=gotas.filter(func(g): return g.idade<g.vida and molhado(g.p))
	for onda in ondas: onda.idade+=delta
	ondas=ondas.filter(func(o): return o.idade<o.vida and molhado(o.p))
	for peixe in peixes:
		if not molhado(peixe.p):
			var p: Vector2=ponto_livre()
			if not p.is_finite(): continue
			peixe.p=p; peixe.origem=p; peixe.destino=p; peixe.espera=1.0; peixe.t=0.0
		peixe.rastro-=delta
		if peixe.espera>0:
			peixe.espera-=delta
			if peixe.espera<=0:
				for tentativa in range(12):
					var alvo: Vector2=(peixe.p+Vector2.RIGHT.rotated(rng.randf_range(-PI,PI))*rng.randf_range(32,100)).snapped(Vector2(2,2))
					if not trajeto_molhado(peixe.p,alvo): continue
					peixe.origem=peixe.p; peixe.destino=alvo; peixe.t=0.0
					peixe.duracao=peixe.p.distance_to(alvo)/rng.randf_range(8,15)
					peixe.dir=peixe.p.direction_to(alvo)
					break
		else:
			peixe.t=minf(float(peixe.t)+delta/maxf(float(peixe.duracao),0.1),1.0)
			var destino: Vector2=peixe.origem.lerp(peixe.destino,smoothstep(0,1,peixe.t))
			if trajeto_molhado(peixe.p,destino): peixe.p=destino
			else: peixe.t=1.0
			if peixe.rastro<=0:
				criar_onda(peixe.p,0.13); peixe.rastro=rng.randf_range(1.8,3.8)
			if peixe.t>=1.0: peixe.espera=rng.randf_range(1.5,4.0)
func _process(delta: float) -> void:
	avancar(delta)
	queue_redraw()
func pixel(p: Vector2,cor: Color,tamanho: Vector2=Vector2(2,2)) -> void:
	if molhado(p): draw_rect(Rect2(p.snapped(Vector2(2,2)),tamanho),cor)
func anel(p: Vector2,raio: float,alpha: float,desloc: float=0.0) -> void:
	for i in range(32):
		if i%8==0: continue
		var a: float=float(i)*TAU/32
		var q: Vector2=p+Vector2(cos(a)*raio,sin(a)*raio*0.48)+Vector2(0,desloc)
		pixel(q,Color(0.54,0.83,0.82,alpha))
func _draw() -> void:
	for peixe in peixes:
		if not molhado(peixe.p): continue
		var corpo: Color=[Color(0.24,0.49,0.49,0.52),Color(0.48,0.56,0.37,0.48),Color(0.31,0.56,0.62,0.5)][peixe.cor]
		var d: Vector2=peixe.dir
		var n: Vector2=Vector2(-d.y,d.x)
		var cauda: float=2.0 if int(tempo*5+peixe.cor)%2==0 else -2.0
		for linha in range(-1,2):
			for coluna in range(-3,3):
				if absi(coluna)+absi(linha)>3: continue
				pixel(peixe.p+d*coluna*2+n*linha*2,corpo.lightened(0.12) if linha<0 else corpo)
		pixel(peixe.p-d*8+n*cauda,corpo)
		pixel(peixe.p-d*10-n*cauda,Color(corpo,0.3))
		pixel(peixe.p+d*4,Color(0.11,0.25,0.29,0.6))
	for onda in ondas:
		var progresso: float=onda.idade/onda.vida
		anel(onda.p,2+progresso*14,(1-progresso)*onda.forca)
		if progresso>0.25: anel(onda.p,2+(progresso-0.25)*12,(1-progresso)*onda.forca*0.35,2)
	for gota in gotas:
		var p: Vector2=gota.p+Vector2(0,-28*(1-gota.idade/gota.vida))
		draw_rect(Rect2(p.snapped(Vector2(2,2)),Vector2(2,4)),Color(0.62,0.83,0.89,0.72))
