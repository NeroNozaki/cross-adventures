extends Node
## Reusable component for any object that publishes to a channel.
## The owner calls send(); it does not need to know who will receive.

@export var channel: StringName = &""


func send(value: Variant = null) -> void:
	if channel == &"":
		push_warning("SignalEmitter has no channel configured at %s." % get_path())
		return
	SignalBus.publish(channel, value)
