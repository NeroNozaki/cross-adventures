extends Node2D
class_name NonInteractable
## Base for objects that receive signals (fence, door, etc.)
## on means activate/open/lowered per convention; invert_receive swaps behavior.

@export var channel: StringName = &""
@export var invert_receive: bool = false
@export var start_activated: bool = false

var _receiver: Node = null
var _is_activated: bool = false


func _ready() -> void:
	_receiver = get_node_or_null("SignalReceiver")
	if _receiver and channel != &"":
		if _receiver.has_method("configure"):
			_receiver.configure(channel)
		if "channel" in _receiver:
			_receiver.channel = channel
		if _receiver.has_signal("received_changed") and not _receiver.received_changed.is_connected(_on_received_changed):
			_receiver.received_changed.connect(_on_received_changed)
		if _receiver.has_signal("received") and not _receiver.received.is_connected(_on_received):
			_receiver.received.connect(_on_received)
	if start_activated:
		_is_activated = true
	else:
		_is_activated = false


func _on_received_changed(is_on: bool) -> void:
	_apply(is_on)


func _on_received(value: Variant) -> void:
	_apply(_interpret(value))


func _interpret(value: Variant) -> bool:
	if typeof(value) == TYPE_BOOL:
		return value
	if typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
		var s := str(value).strip_edges().to_lower()
		if s in ["on", "true", "1", "open", "lower", "down", "blue", "gold", "pressed"]:
			return true
		if s in ["off", "false", "0", "closed", "raise", "up", "red", "unpressed"]:
			return false
		return false
	if typeof(value) == TYPE_INT:
		return value != 0
	return bool(value)


func _apply(is_on: bool) -> void:
	var activate := is_on
	if invert_receive:
		activate = !activate
	if activate == _is_activated:
		return
	_is_activated = activate
	_on_activated(activate)


func _on_activated(activated: bool) -> void:
	pass
