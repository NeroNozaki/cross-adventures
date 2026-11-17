class_name SignalGateInput
extends Resource

@export var canal: StringName = &""
@export var inverter: bool = false
@export var valor_inicial: bool = false
@export var no_emissor: NodePath


func _init(canal_entrada: StringName = &"", inverter_entrada: bool = false, valor_entrada: bool = false) -> void:
	canal = canal_entrada
	inverter = inverter_entrada
	valor_inicial = valor_entrada
