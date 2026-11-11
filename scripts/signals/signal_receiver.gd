extends Node
## Reusable component for any object that listens to a channel.
## The owner connects the 'received' signal; it does not need to know who published.

signal received(value: Variant)

@export var channel: StringName = &""

var _current_channel: StringName = &""


func _ready() -> void:
	configure(channel)


func configure(new_channel: StringName) -> void:
	if new_channel == _current_channel:
		return
	if _current_channel != &"":
		SignalBus.unsubscribe(_current_channel, _on_received)
	_current_channel = new_channel
	if _current_channel != &"":
		SignalBus.subscribe(_current_channel, _on_received)


func _exit_tree() -> void:
	if _current_channel != &"":
		SignalBus.unsubscribe(_current_channel, _on_received)


func _on_received(value: Variant) -> void:
	received.emit(value)
