extends BaseArea

const CANAIS_SWITCHES: Array[StringName] = [&"area1_switch2", &"area1_switch3", &"area1_switch4"]

@onready var fence3: Fence = $objects/fence3
@onready var fence4: Fence = $objects/fence4
@onready var fence_set3: FenceSet = $objects/fence_set3

var _callbacks: Dictionary = {}
var _acionados: Dictionary = {}


func _ready() -> void:
	super._ready()
	for canal in CANAIS_SWITCHES:
		_acionados[canal] = false
		var callback := _on_switch_publicou.bind(canal)
		_callbacks[canal] = callback
		SignalBus.subscribe(canal, callback)
	_atualizar_fences()


func _exit_tree() -> void:
	if not is_instance_valid(SignalBus):
		return
	for canal in _callbacks:
		SignalBus.unsubscribe(canal, _callbacks[canal])


func _on_switch_publicou(valor: Variant, canal: StringName) -> void:
	if str(valor).to_lower() != "gold":
		return
	_acionados[canal] = true
	_atualizar_fences()


func _atualizar_fences() -> void:
	var todos_acionados := true
	for canal in CANAIS_SWITCHES:
		if not _acionados.get(canal, false):
			todos_acionados = false
			break
	fence3.definir_ativado(todos_acionados)
	fence4.definir_ativado(todos_acionados)
	fence_set3.definir_ativado(todos_acionados)
