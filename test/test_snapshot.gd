extends Node

func _ready() -> void:
	var snap = EntitySnapshot.new()
	snap.entity_id = "test_entity"
	snap.health_current = 100.0
	snap.health_max = 150.0
	print("Snapshot creado:", snap.entity_id, "| HP:", snap.health_current, "/", snap.health_max)
