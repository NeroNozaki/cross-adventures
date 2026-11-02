extends Node
## Signal bus by channel.
## Emitters publish to a channel; receivers subscribed to the same channel get
## the value. Neither side needs to know the other.

var _subscribers: Dictionary = {}


func publish(channel: StringName, value: Variant = null) -> void:
	if channel == &"" or not _subscribers.has(channel):
		return
	var subscribers: Array = _subscribers[channel].duplicate()
	for callback in subscribers:
		if callback is Callable and callback.is_valid():
			callback.call(value)
	_remove_invalid(channel)


func subscribe(channel: StringName, callback: Callable) -> void:
	if channel == &"" or not callback.is_valid():
		return
	if not _subscribers.has(channel):
		_subscribers[channel] = []
	var subscribers: Array = _subscribers[channel]
	if not subscribers.has(callback):
		subscribers.append(callback)


func unsubscribe(channel: StringName, callback: Callable) -> void:
	if not _subscribers.has(channel):
		return
	var subscribers: Array = _subscribers[channel]
	subscribers.erase(callback)
	if subscribers.is_empty():
		_subscribers.erase(channel)


func _remove_invalid(channel: StringName) -> void:
	if not _subscribers.has(channel):
		return
	var subscribers: Array = _subscribers[channel]
	for i in range(subscribers.size() - 1, -1, -1):
		if not subscribers[i].is_valid():
			subscribers.remove_at(i)
	if subscribers.is_empty():
		_subscribers.erase(channel)
