extends Node2D
class_name Interactable
## Base for objects the player interacts with directly (button, switch, etc.)
## Sends true/false on/off signals via channel with invert_send support.

@export var channel: StringName = &""
@export var invert_send: bool = false

var _emitter: Node = null


func _ready() -> void:
	_emitter = get_node_or_null("SignalEmitter")
	if _emitter and channel != &"":
		if "channel" in _emitter:
			_emitter.channel = channel


func send_on_off(is_on: bool) -> void:
	var value: bool = is_on
	if invert_send:
		value = !value
	if _emitter and _emitter.has_method("send"):
		_emitter.send(value)
		return
	if channel != &"" and has_node("/root/SignalBus"):
		SignalBus.publish(channel, value)


func publish_value(value: Variant) -> void:
	if _emitter and _emitter.has_method("send"):
		_emitter.send(value)
		return
	if channel != &"" and has_node("/root/SignalBus"):
		SignalBus.publish(channel, value)
