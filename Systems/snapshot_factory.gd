class_name SnapshotFactory
extends Node

func create_snapshot(entity: Node) -> EntitySnapshot:
	var snap = EntitySnapshot.new()
	snap.entity_id = str(entity.name)
	snap.timestamp = 0

	# Leer salud desde Health
	var health_component = entity.get_node_or_null("Health")
	if health_component:
		if health_component.has_method("get_health"):
			snap.health_current = float(health_component.call("get_health"))
			snap.health_max = float(health_component.call("get_health_max"))

	# Leer postura desde PostureSystem
	var posture_component = entity.get_node_or_null("PostureSystem")
	if posture_component:
		if posture_component.has_method("get_posture"):
			snap.posture_current = float(posture_component.call("get_posture"))
			snap.posture_max = float(posture_component.call("get_posture_max"))

	# Leer corazones desde LivesSystem
	var lives_component = entity.get_node_or_null("LivesSystem")
	if lives_component:
		if lives_component.has_method("get_hearts"):
			snap.hearts_current = int(lives_component.call("get_hearts"))

	# Flags de captura
	if entity.has_method("is_capturing"):
		snap.is_capturing = bool(entity.call("is_capturing"))
	if entity.has_method("is_captured"):
		snap.is_captured = bool(entity.call("is_captured"))

	# Posición si es Node3D
	if entity is Node3D:
		snap.position = entity.global_transform.origin

	return snap
