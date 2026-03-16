extends Node

signal event_emitted(event_id: String, payload: Dictionary, metadata: Dictionary)

func emit_event(event_id: String, payload := {}, metadata := {}) -> void:
	if typeof(metadata) != TYPE_DICTIONARY:
		metadata = {}

	var payload_copy = payload.duplicate(true)
	event_emitted.emit(event_id, payload_copy, metadata)
