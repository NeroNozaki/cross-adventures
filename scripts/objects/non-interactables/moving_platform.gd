extends NonInteractable
class_name MovingPlatform

@export var move_speed: float = 96.0
@export var carry_riders: bool = true

@onready var platform: Node2D = $Platform
@onready var inactive_anchor: Marker2D = $InactiveAnchor
@onready var active_anchor: Marker2D = $ActiveAnchor
@onready var tilemap: TileMapLayer = $Platform/TileMapLayer

var _moving: bool = false
var _move_from: Vector2 = Vector2.ZERO
var _move_to: Vector2 = Vector2.ZERO
var _move_elapsed: float = 0.0
var _move_duration: float = 0.0
var _riders: Array[Node2D] = []
var _hole_field: HoleField = null
var _blocker_registered: bool = false


func _ready() -> void:
	super._ready()
	var inicial: Marker2D = active_anchor if _is_activated else inactive_anchor
	platform.global_position = inicial.global_position
	_criar_area_passageiros()
	call_deferred("_atualizar_bloqueador")
	set_physics_process(false)


func _exit_tree() -> void:
	_remover_bloqueador()
	_riders.clear()


func _on_activated(activated: bool) -> void:
	var destino: Marker2D = active_anchor if activated else inactive_anchor
	_iniciar_movimento(destino.global_position)


func _iniciar_movimento(destino: Vector2) -> void:
	if platform.global_position.distance_squared_to(destino) < 0.01:
		_moving = false
		set_physics_process(false)
		return
	_move_from = platform.global_position
	_move_to = destino
	_move_elapsed = 0.0
	_move_duration = maxf(_move_from.distance_to(_move_to) / maxf(move_speed, 0.001), 0.01)
	_moving = true
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _moving:
		return
	var antes: Vector2 = platform.global_position
	_move_elapsed += delta
	var proporcao: float = clampf(_move_elapsed / _move_duration, 0.0, 1.0)
	var destino: Vector2 = _move_from.lerp(_move_to, smoothstep(0.0, 1.0, proporcao))
	if proporcao >= 1.0:
		destino = _move_to
		_moving = false
		set_physics_process(false)
	platform.global_position = destino
	_mover_passageiros(destino - antes)
	_atualizar_bloqueador()


func esta_em_movimento() -> bool:
	return _moving


func obter_area_passageiros() -> Area2D:
	if tilemap == null:
		return null
	return tilemap.get_node_or_null("RiderArea") as Area2D


func obter_retangulo_bloqueio() -> Rect2:
	if tilemap == null or tilemap.tile_set == null:
		return Rect2()
	var usados: Rect2i = tilemap.get_used_rect()
	if usados.size.x <= 0 or usados.size.y <= 0:
		return Rect2()
	var tamanho: Vector2 = Vector2(tilemap.tile_set.tile_size)
	var local := Rect2(Vector2(usados.position) * tamanho, Vector2(usados.size) * tamanho)
	var transformacao: Transform2D = tilemap.global_transform
	var cantos: Array[Vector2] = [
		transformacao * local.position,
		transformacao * Vector2(local.end.x, local.position.y),
		transformacao * local.end,
		transformacao * Vector2(local.position.x, local.end.y),
	]
	var minimo: Vector2 = cantos[0]
	var maximo: Vector2 = cantos[0]
	for canto in cantos:
		minimo.x = minf(minimo.x, canto.x)
		minimo.y = minf(minimo.y, canto.y)
		maximo.x = maxf(maximo.x, canto.x)
		maximo.y = maxf(maximo.y, canto.y)
	return Rect2(minimo, maximo - minimo)


func _obter_campo_de_buraco() -> HoleField:
	if is_instance_valid(_hole_field) and _hole_field.is_inside_tree():
		return _hole_field
	_hole_field = null
	if is_inside_tree():
		_hole_field = get_tree().get_first_node_in_group("hole_fields") as HoleField
	return _hole_field


func _atualizar_bloqueador() -> void:
	var campo: HoleField = _obter_campo_de_buraco()
	if campo == null:
		return
	var retangulo: Rect2 = obter_retangulo_bloqueio()
	if retangulo.size.x <= 0.0 or retangulo.size.y <= 0.0:
		return
	campo.registrar_bloqueador(get_instance_id(), retangulo)
	_blocker_registered = true


func _remover_bloqueador() -> void:
	if not _blocker_registered:
		return
	if is_instance_valid(_hole_field):
		_hole_field.remover_bloqueador(get_instance_id())
	_blocker_registered = false


func _criar_area_passageiros() -> void:
	if not carry_riders:
		return
	var area: Area2D = _criar_area("RiderArea")
	if area == null:
		return
	area.body_entered.connect(_on_passageiro_entrou)
	area.body_exited.connect(_on_passageiro_saiu)


func _criar_area(nome: String) -> Area2D:
	if tilemap == null or tilemap.tile_set == null:
		return null
	var usados: Rect2i = tilemap.get_used_rect()
	if usados.size.x <= 0 or usados.size.y <= 0:
		return null
	var tamanho_tile := Vector2(tilemap.tile_set.tile_size)
	var area := Area2D.new()
	area.name = nome
	area.collision_layer = 0
	area.set_collision_mask_value(PhysicsLayers.HERO, true)
	var colisao := CollisionShape2D.new()
	var formato := RectangleShape2D.new()
	formato.size = Vector2(usados.size) * tamanho_tile
	colisao.shape = formato
	colisao.position = (Vector2(usados.position) + Vector2(usados.size) * 0.5) * tamanho_tile
	area.add_child(colisao)
	tilemap.add_child(area)
	return area


func _on_passageiro_entrou(body: Node2D) -> void:
	if body.is_in_group("herois") and not _riders.has(body):
		_riders.append(body)


func _on_passageiro_saiu(body: Node2D) -> void:
	_riders.erase(body)


func _mover_passageiros(delta: Vector2) -> void:
	if not carry_riders or delta.is_zero_approx():
		return
	for indice in range(_riders.size() - 1, -1, -1):
		var passageiro: Node2D = _riders[indice]
		if not is_instance_valid(passageiro) or not passageiro.is_inside_tree():
			_riders.remove_at(indice)
			continue
		if passageiro.get("esta_morto") == true or passageiro.get("caindo") == true:
			continue
		passageiro.global_position += delta
