class_name SignalGate
extends Node

@export var entradas: Array[SignalGateInput] = []
@export var canal_saida: StringName = &""
@export var single_use: bool = false

var _valores: Array[bool] = []
var _conexoes: Array[Dictionary] = []
var _saida_ativa: bool = false
var _travado: bool = false


func _ready() -> void:
	_configurar_entradas()
	call_deferred("_avaliar_inicial")


func _exit_tree() -> void:
	_desconectar_entradas()


func esta_ativado() -> bool:
	return _saida_ativa


func obter_valores() -> Array[bool]:
	return _valores.duplicate()


func _configurar_entradas() -> void:
	_desconectar_entradas()
	_valores.clear()
	for indice in entradas.size():
		var entrada := entradas[indice]
		if entrada == null:
			_valores.append(false)
			continue
		_valores.append(_valor_condicao(entrada.valor_inicial, entrada))
		if entrada.canal == &"":
			continue
		var callback := _ao_receber.bind(indice)
		_conexoes.append({"canal": entrada.canal, "callback": callback})
		var barramento := get_node_or_null("/root/SignalBus")
		if barramento:
			barramento.subscribe(entrada.canal, callback)


func _desconectar_entradas() -> void:
	var barramento := get_node_or_null("/root/SignalBus")
	for conexao in _conexoes:
		if barramento:
			barramento.unsubscribe(conexao["canal"], conexao["callback"])
	_conexoes.clear()


func _ao_receber(valor: Variant, indice: int) -> void:
	if _travado or indice < 0 or indice >= entradas.size():
		return
	var entrada := entradas[indice]
	if entrada == null:
		return
	_valores[indice] = _valor_condicao(SignalValue.para_bool(valor), entrada)
	_avaliar_e_publicar()


func _avaliar_inicial() -> void:
	if not is_inside_tree():
		return
	_avaliar_e_publicar()


func _avaliar_e_publicar() -> void:
	if _travado:
		return
	var condicao := _condicao_atendida()
	if condicao == _saida_ativa:
		return
	_saida_ativa = condicao
	_publicar(condicao)
	if single_use and condicao:
		_travado = true
		_travar_emissores()


func _condicao_atendida() -> bool:
	if _valores.is_empty():
		return false
	for valor in _valores:
		if not valor:
			return false
	return true


func _valor_condicao(valor: bool, entrada: SignalGateInput) -> bool:
	return not valor if entrada.inverter else valor


func _publicar(valor: bool) -> void:
	if canal_saida == &"":
		return
	var barramento := get_node_or_null("/root/SignalBus")
	if barramento:
		barramento.publish(canal_saida, valor)


func _travar_emissores() -> void:
	for entrada in entradas:
		if entrada == null or entrada.no_emissor.is_empty():
			continue
		var emissor := get_node_or_null(entrada.no_emissor)
		if emissor == null:
			push_warning("SignalGate nao encontrou o emissor de %s em %s." % [entrada.canal, get_path()])
			continue
		if emissor.has_method("travar_estado_atual"):
			emissor.travar_estado_atual()


func _get_configuration_warnings() -> PackedStringArray:
	var avisos := PackedStringArray()
	if entradas.is_empty():
		avisos.append("Adicione ao menos uma entrada de sinal.")
	if canal_saida == &"":
		avisos.append("Defina o canal de saida.")
	var canais: Dictionary = {}
	for indice in entradas.size():
		var entrada := entradas[indice]
		if entrada == null:
			avisos.append("A entrada %d esta vazia." % indice)
			continue
		if entrada.canal == &"":
			avisos.append("A entrada %d nao tem canal." % indice)
		elif canais.has(entrada.canal):
			avisos.append("O canal %s aparece mais de uma vez." % entrada.canal)
		else:
			canais[entrada.canal] = true
		if single_use and entrada.no_emissor.is_empty():
			avisos.append("A entrada %s precisa de no_emissor para travar em single_use." % entrada.canal)
		elif not entrada.no_emissor.is_empty() and get_node_or_null(entrada.no_emissor) == null:
			avisos.append("O no_emissor da entrada %s nao foi encontrado." % entrada.canal)
	return avisos
