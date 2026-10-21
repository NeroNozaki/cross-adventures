extends Node2D
## Som espacial por instancia. Passos dependem de distancia realmente percorrida.

signal som_reproduzido(evento: StringName, arquivo: String)

@export var perfil: Resource
var distancia_acumulada: float = 0.0
var morto: bool = false
var ultimos: Dictionary = {}
var espera_bloqueio: float = 0.0

@onready var passos_player: AudioStreamPlayer2D = $Passos
@onready var acoes_player: AudioStreamPlayer2D = $Acoes
@onready var impactos_player: AudioStreamPlayer2D = $Impactos
@onready var estado_player: AudioStreamPlayer2D = $Estado
@onready var atraso_morte: Timer = $AtrasoMorte

func _ready() -> void:
	atraso_morte.timeout.connect(_reproduzir.bind(&"morte"))

func _process(delta: float) -> void:
	espera_bloqueio = maxf(0.0, espera_bloqueio - delta)

func registrar_movimento(distancia: float, caminhando: bool) -> void:
	if morto or perfil == null:
		return
	if not caminhando or distancia <= 0.001:
		distancia_acumulada = 0.0
		return
	distancia_acumulada += distancia
	if distancia_acumulada >= perfil.distancia_entre_passos:
		distancia_acumulada = fmod(distancia_acumulada, perfil.distancia_entre_passos)
		tocar(&"passo")

func tocar(evento: StringName) -> void:
	if perfil == null or morto:
		return
	if evento == &"bloqueio":
		if espera_bloqueio > 0.0:
			return
		espera_bloqueio = 0.08
	_reproduzir(evento)

func finalizar() -> void:
	if morto:
		return
	morto = true
	distancia_acumulada = 0.0
	passos_player.stop()
	acoes_player.stop()
	impactos_player.stop()
	estado_player.stop()
	if perfil == null:
		return
	if perfil.atraso_morte > 0.0:
		atraso_morte.start(perfil.atraso_morte)
	else:
		_reproduzir(&"morte")

func _reproduzir(evento: StringName) -> void:
	if perfil == null:
		return
	var lista: Array[AudioStream] = perfil.clipes(evento)
	if lista.is_empty():
		return
	var indice: int = randi_range(0, lista.size() - 1)
	if lista.size() > 1 and ultimos.get(evento, -1) == indice:
		indice = (indice + 1) % lista.size()
	ultimos[evento] = indice
	var player: AudioStreamPlayer2D = acoes_player
	var volume: float = perfil.volume_acoes_db
	if evento == &"passo":
		player = passos_player
		volume = perfil.volume_passos_db
	elif evento == &"acerto" or evento == &"bloqueio" or evento == &"ricochete":
		player = impactos_player
		volume = perfil.volume_impactos_db
	elif evento == &"dano" or evento == &"morte":
		player = estado_player
		volume = perfil.volume_impactos_db
	player.stream = lista[indice]
	player.pitch_scale = clampf(perfil.tom_base + randf_range(-0.045, 0.045), 0.65, 1.4)
	player.volume_db = volume
	player.play()
	som_reproduzido.emit(evento, player.stream.resource_path)
