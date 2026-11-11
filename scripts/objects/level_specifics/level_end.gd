extends Area2D
class_name LevelEnd
## Both heroes must overlap this area. Their controls are disabled, they walk
## out in the direction they were facing and the scene transition starts at the
## same time.

signal saida_iniciada

@export_file("*.tscn") var proxima_cena: String = "res://cenas/screens/start_menu.tscn"
@export_range(0.1, 3.0, 0.1, "suffix:s") var tempo_caminhada: float = 1.0

var _jogadores_dentro: Array[Node2D] = []
var _jogadores: Array[Node2D] = []
var _direcoes: Array[Vector2] = []
var _iniciado := false
var _caminhando := false
var _tempo_restante := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(PhysicsLayers.HERO, true)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func foi_iniciado() -> bool:
	return _iniciado


func esta_caminhando() -> bool:
	return _caminhando


func _physics_process(delta: float) -> void:
	if not _caminhando:
		return
	var passo: float = minf(delta, _tempo_restante)
	for i in _jogadores.size():
		var jogador: Node2D = _jogadores[i]
		if is_instance_valid(jogador):
			jogador.mover(_direcoes[i], passo)
	_tempo_restante -= delta
	if _tempo_restante <= 0.0:
		_caminhando = false


func _on_body_entered(body: Node2D) -> void:
	if _iniciado or not body.is_in_group("herois"):
		return
	if body not in _jogadores_dentro:
		_jogadores_dentro.append(body)
	if _todos_os_jogadores_dentro():
		_iniciar_saida()


func _on_body_exited(body: Node2D) -> void:
	if _iniciado:
		return
	_jogadores_dentro.erase(body)


func _todos_os_jogadores_dentro() -> bool:
	var herois: Array[Node] = get_tree().get_nodes_in_group("herois")
	if herois.size() < 2:
		return false
	for heroi in herois:
		if heroi not in _jogadores_dentro:
			return false
	return true


func _iniciar_saida() -> void:
	_iniciado = true
	_jogadores = _jogadores_dentro.duplicate()
	_direcoes.clear()
	for jogador in _jogadores:
		var direcao: Vector2 = jogador.frente
		if direcao.length_squared() < 0.001:
			direcao = Vector2.DOWN
		_direcoes.append(direcao.normalized())
		_desligar_controle(jogador)
	_tempo_restante = tempo_caminhada
	_caminhando = true
	saida_iniciada.emit()
	_iniciar_transicao()


func _desligar_controle(jogador: Node2D) -> void:
	if jogador.has_method("cancelar_carga"):
		jogador.cancelar_carga()
	if jogador.has_method("cancelar_dash"):
		jogador.cancelar_dash()
	if jogador.has_method("definir_defesa"):
		jogador.definir_defesa(false)
	jogador.controlado = false
	jogador.atacando = false
	jogador.defendendo = false
	jogador.tempo_empurrao = 0.0
	jogador.velocity = Vector2.ZERO
	var mira: Node = jogador.get("mira")
	if mira is CanvasItem:
		mira.hide()
	jogador.set_physics_process(false)
	jogador.process_mode = Node.PROCESS_MODE_ALWAYS


func _iniciar_transicao() -> void:
	if proxima_cena.is_empty():
		return
	var fluxo: Node = get_node_or_null("/root/FluxoTela")
	if fluxo and fluxo.has_method("trocar"):
		fluxo.trocar(proxima_cena)
	else:
		push_error("FluxoTela nao encontrado para trocar a cena.")
