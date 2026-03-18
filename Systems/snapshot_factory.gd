class_name SnapshotFactory
extends Node

func create_snapshot(entity: Node) -> EntitySnapshot:
	var snap = EntitySnapshot.new()

	if entity == null:
		push_error("SnapshotFactory: entidad null")
		return snap

	snap.entity_id = str(entity.name)
	snap.timestamp = Time.get_ticks_msec()
	# === CAPTURE STAMINA — voluntad de resistir / energía de agarre (jugador y presa) ===
	var cap := entity.get_node_or_null("CaptureStaminaComponent")
	if cap:
		snap.capture_stamina_current = cap.get_capture_stamina() if cap.has_method("get_capture_stamina") else cap.current_capture_stamina
		snap.capture_stamina_max     = cap.get_capture_stamina_max() if cap.has_method("get_capture_stamina_max") else cap.max_capture_stamina
		snap.capture_resistance      = cap.get_capture_resistance() if cap.has_method("get_capture_resistance") else cap.capture_resistance
	
	# === SALUD — mismo nombre en todos los actores ===
	var health = entity.get_node_or_null("HealthComponent")
	if health:
		snap.health_current = health.get_health()     if health.has_method("get_health")     else health.current_health
		snap.health_max     = health.get_health_max() if health.has_method("get_health_max") else health.max_health
	else:
		push_warning("SnapshotFactory: %s no tiene HealthComponent" % entity.name)

	# === POSTURA — mismo nombre en todos los actores ===
	var posture = entity.get_node_or_null("PostureComponent")
	if posture:
		snap.posture_current = posture.get_posture()     if posture.has_method("get_posture")     else posture.current_posture
		snap.posture_max     = posture.get_posture_max() if posture.has_method("get_posture_max") else posture.max_posture
		# Capturamos si ya está rota para que el DamageResolver lo sepa
		if posture.has_method("is_broken"):
			snap.physical_state = "POSTURE_BROKEN" if posture.is_broken() else ""
		elif posture.has_method("is_posture_broken"):
			snap.physical_state = "POSTURE_BROKEN" if posture.is_posture_broken() else ""
	else:
		push_warning("SnapshotFactory: %s no tiene PostureComponent" % entity.name)

	# === CORAZONES — exclusivo del jugador, no falla si no existe ===
	var lives = entity.get_node_or_null("LivesSystem")
	if lives:
		snap.hearts_current = lives.get_hearts()

	# === FLAGS ===
	snap.is_capturing = entity.call("is_capturing") if entity.has_method("is_capturing") else false
	snap.is_captured  = entity.call("is_captured")  if entity.has_method("is_captured")  else false

	# === POSICIÓN ===
	if entity is Node3D:
		snap.position = entity.global_transform.origin

	return snap
