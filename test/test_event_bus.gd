extends Node

func _ready() -> void:
	print("Test node _ready() ejecutado")
	# Opción A: pasar Callable (recomendado)
	EventBus.connect("event_emitted", Callable(self, "_on_event_emitted"))
	print("Conectado a EventBus")
	# Emite un evento (incluye metadata)
	EventBus.emit_event("EVT_PRUEBA", {"msg": "hola"}, {"priority": 5})
	print("Evento emitido desde Test node")

func _on_event_emitted(event_id: String, payload: Dictionary, metadata: Dictionary) -> void:
	print("EVENT RECIBIDO:", event_id, payload, metadata)
