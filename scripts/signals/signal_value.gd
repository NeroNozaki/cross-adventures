class_name SignalValue
extends RefCounted


static func para_bool(valor: Variant) -> bool:
	match typeof(valor):
		TYPE_BOOL:
			return valor
		TYPE_STRING, TYPE_STRING_NAME:
			var s := str(valor).strip_edges().to_lower()
			if s in ["on", "true", "1", "open", "lower", "down", "blue", "gold", "pressed"]:
				return true
			if s in ["off", "false", "0", "closed", "raise", "up", "red", "unpressed"]:
				return false
			return false
		TYPE_INT:
			return valor != 0
		TYPE_FLOAT:
			return not is_zero_approx(float(valor))
		_:
			return false
