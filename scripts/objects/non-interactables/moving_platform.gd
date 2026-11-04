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


func _ready() -> void:
	super._ready()
	var inicial: Marker2D = active_anchor if _is_activated else inactive_anchor
	platform.global_position = inicial.global_position
	_criar_area_passageiros()
	set_physics_process(false)


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


func esta_em_movimento() -> bool:
	return _moving


func obter_area_passageiros() -> Area2D:
	if tilemap == null:
		return null
	return tilemap.get_node_or_null("RiderArea") as Area2D


func _criar_area_passageiros() -> void:
	if not carry_riders or tilemap == null or tilemap.tile_set == null:
		return
	var usados: Rect2i = tilemap.get_used_rect()
	if usados.size.x <= 0 or usados.size.y <= 0:
		return
	var tamanho_tile := Vector2(tilemap.tile_set.tile_size)
	var area := Area2D.new()
	area.name = "RiderArea"
	area.collision_layer = 0
	area.set_collision_mask_value(PhysicsLayers.HERO, true)
	var colisao := CollisionShape2D.new()
	var formato := RectangleShape2D.new()
	formato.size = Vector2(usados.size) * tamanho_tile
	colisao.shape = formato
	colisao.position = (Vector2(usados.position) + Vector2(usados.size) * 0.5) * tamanho_tile
	area.add_child(colisao)
	tilemap.add_child(area)
	area.body_entered.connect(_on_passageiro_entrou)
	area.body_exited.connect(_on_passageiro_saiu)


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
