extends Node
class_name CaptureResolver

signal capture_resolved(result: String)

# === Constantes de drenaje ===
const DRAIN_PER_SECOND_CAPTOR: float  = 8.0
const DRAIN_PER_SECOND_PREY: float    = 12.0
const DRAIN_PER_HIT_LIGHT: float      = 15.0
const DRAIN_PER_HIT_HEAVY: float      = 30.0
const DRAIN_ON_CAPTOR_HIT: float      = 25.0

# === Recompensas (éxito) ===
const REWARD_HEALTH: float  = 25.0
const REWARD_HEARTS: int    = 1

# === Penalizaciones (fallo) ===
const PENALTY_POSTURE: float = 20.0
const PENALTY_HEALTH: float  = 15.0
const PENALTY_STUN_TIME: float = 1.5
const PENALTY_HEARTS: int   = 1

# === Estado interno ===
var is_active: bool = false
var captor: Node = null
var prey: Node   = null

var captor_stamina: CaptureStaminaComponent = null
var prey_stamina: CaptureStaminaComponent   = null
var speed_multiplier: float = 0.6

# === Forcejeo — rangos de intervalo por capacidad ===
var struggle_timer: float = 0.0
var struggle_interval_min: float = 0.4
var struggle_interval_max: float = 0.9
var capture_combo_index: int = 0
var prey_stamina_depleted: bool = false

func update(delta: float) -> void:
	if not is_active:
		return

	# La presa queda anclada frente al hocico del jugador
	if is_instance_valid(prey) and is_instance_valid(captor):
		var prey_body := prey as CharacterBody3D
		if prey_body:
			# Offset frente al captor en la dirección que mira
			var forward: Vector3 = -captor.global_transform.basis.z.normalized()
			var anchor_pos: Vector3 = captor.global_position + forward * 0.8
			anchor_pos.y = captor.global_position.y
			prey_body.global_position = anchor_pos
	
	# Si el jugador se mueve durante el combo → reiniciar
	if capture_combo_index > 0 and is_instance_valid(captor):
		var captor_body := captor as CharacterBody3D
		if captor_body:
			var horizontal_speed := Vector2(captor_body.velocity.x, captor_body.velocity.z).length()
			if horizontal_speed > 0.5:
				capture_combo_index = 0
				print("↩️ Combo captura reiniciado — jugador se movió")
	
	# Forcejeo activo de la presa
	struggle_timer -= delta
	if struggle_timer <= 0.0:
		struggle_timer = randf_range(struggle_interval_min, struggle_interval_max)
		_apply_struggle_hit()
	
	# Drenaje pasivo por tiempo
	captor_stamina.apply_drain(DRAIN_PER_SECOND_CAPTOR * delta)
	prey_stamina.apply_drain(DRAIN_PER_SECOND_PREY * prey_stamina.capture_resistance * delta)

	# Evaluar condiciones de fin (orden del NT §17.5.1)
# Evaluar condiciones de fin
	if captor_stamina.is_depleted():
		_resolve_verdict("FALLO")
	elif prey_stamina.is_depleted():
		prey_stamina_depleted = true
		# NO resolvemos aquí — esperamos el golpe 3


func start_capture(_captor: Node, _prey: Node) -> bool:
	capture_combo_index = 0
	prey_stamina_depleted = false
	if is_active:
		return false

	captor = _captor
	prey   = _prey

	captor_stamina = captor.get_node_or_null("CaptureStaminaComponent")
	prey_stamina   = prey.get_node_or_null("CaptureStaminaComponent")

	if captor_stamina == null or prey_stamina == null:
		push_error("CaptureResolver: falta CaptureStaminaComponent en captor o presa")
		return false

	captor_stamina.reset()
	prey_stamina.reset()

	is_active = true

	# Leer peso de la presa
	var weight: String = prey_stamina.capture_weight
	match weight:
		"LIVIANO":	speed_multiplier = 0.8
		"MEDIO":	speed_multiplier = 0.6
		"PESADO":	speed_multiplier = 0.4
		_:			speed_multiplier = 0.6
		
		# Leer capacidad de forcejeo
	match prey_stamina.capacidad_forcejeo:
		"BAJA":
			struggle_interval_min = 1.2
			struggle_interval_max = 2.5
		"MEDIA":
			struggle_interval_min = 0.6
			struggle_interval_max = 1.4
		"ALTA":
			struggle_interval_min = 0.3
			struggle_interval_max = 0.8
		_:
			struggle_interval_min = 0.6
			struggle_interval_max = 1.4

		# Primer golpe con retardo aleatorio
	struggle_timer = randf_range(struggle_interval_min, struggle_interval_max)
	
	# Transiciones de estado físico
	EventBus.emit_event("EVT_INTENTO_CAPTURA", {
		"captor_id":captor.name,
		"prey_id":	prey.name
	}, {"priority":	10})

	print("🐱 Captura iniciada: %s → %s" % [captor.name, prey.name])
	var prey_state := prey.get_node_or_null("EnemyStateMachine") as EnemyStateMachine
	if prey_state:
		prey_state._change_state(EnemyStateMachine.PhysicalState.CAPTURED)
	return true

func register_hit_on_prey() -> void:
	if not is_active:
		return

	if capture_combo_index >= 3:
		capture_combo_index = 1
	else:
		capture_combo_index += 1

	var is_heavy: bool = capture_combo_index == 3
	print("Combo Captura: %d | Crítico: %s" % [capture_combo_index, is_heavy])

	notify_player_hit_prey(is_heavy)

	# Golpe 3 — verificar si la presa ya estaba lista para rematar
	if capture_combo_index == 3 and prey_stamina_depleted:
		_resolve_verdict("EXITO")

func _apply_struggle_hit() -> void:
	# Daño definido por ADN (via export en CaptureStaminaComponent)
	var damage: float = prey_stamina.forcejeo_damage
	captor_stamina.apply_drain(damage)
	print("🐾 Forcejeo: -%.1f capture_stamina (jugador)" % damage)

	# Micro daño de postura — presión, no letal
	var posture_comp := captor.get_node_or_null("PostureComponent")
	if posture_comp and posture_comp.has_method("apply_posture_damage"):
		posture_comp.apply_posture_damage(2.0)

func notify_player_hit_prey(is_heavy_hit: bool = false) -> void:
	if not is_active:
		return
	var drain := DRAIN_PER_HIT_HEAVY if is_heavy_hit else DRAIN_PER_HIT_LIGHT
	prey_stamina.apply_drain(drain)
	print("🐾 Golpe a la presa: -%.0f capture_stamina (presa)" % drain)


func notify_captor_received_hit() -> void:
	if not is_active:
		return
	captor_stamina.apply_drain(DRAIN_ON_CAPTOR_HIT)
	print("💥 Captor golpeado: -%.0f capture_stamina (jugador)" % DRAIN_ON_CAPTOR_HIT)


func cancel_capture() -> void:
	if not is_active:
		return
	_resolve_verdict("CANCELADO")


func _resolve_verdict(result: String) -> void:
	is_active = false

	match result:
		"EXITO":
			print("✅ Captura EXITOSA")
			EventBus.emit_event("EVT_CAPTURA_EXITOSA", {
				"captor_id": captor.name,
				"prey_id":   prey.name
			}, {"priority": 10})
			_apply_rewards()
			prey.die()

		"FALLO":
			print("❌ Captura FALLIDA — Liberación forzada")
			EventBus.emit_event("EVT_INTENTO_CAPTURA_FALLIDO", {
				"captor_id": captor.name,
				"prey_id":   prey.name
			}, {"priority": 10})
			EventBus.emit_event("EVT_LIBERACION_FORZADA", {
				"captor_id": captor.name,
				"prey_id":   prey.name
			}, {"priority": 10})
			_apply_penalties()

		"CANCELADO":
			print("↩️ Captura CANCELADA")
			EventBus.emit_event("EVT_JUGADOR_CANCELA_CAZA", {
				"captor_id": captor.name,
				"prey_id":   prey.name
			}, {"priority": 10})
			_apply_minor_penalty()

	capture_resolved.emit(result)
	_cleanup()


func _apply_rewards() -> void:
	var health_comp := captor.get_node_or_null("HealthComponent")
	if health_comp and health_comp.has_method("heal"):
		health_comp.heal(REWARD_HEALTH)
		print("💚 Recompensa: +%.0f vida" % REWARD_HEALTH)

	var lives_comp := captor.get_node_or_null("LivesSystem")
	if lives_comp and lives_comp.has_method("restore_heart"):
		lives_comp.restore_heart(REWARD_HEARTS)
		print("💚 Recompensa: +%d corazón(es)" % REWARD_HEARTS)


func _apply_penalties() -> void:
	var posture_comp := captor.get_node_or_null("PostureComponent")
	if posture_comp and posture_comp.has_method("apply_posture_damage"):
		posture_comp.apply_posture_damage(PENALTY_POSTURE)

	var health_comp := captor.get_node_or_null("HealthComponent")
	if health_comp and health_comp.has_method("apply_damage"):
		health_comp.apply_damage(PENALTY_HEALTH)

	var lives_comp := captor.get_node_or_null("LivesSystem")
	if lives_comp and lives_comp.has_method("consume_heart"):
		lives_comp.consume_heart()

	# Empuje en dirección contraria a la presa (el golpe de liberación)
	var captor_body := captor as CharacterBody3D
	if captor_body and is_instance_valid(prey):
		var push_dir: Vector3 = (captor.global_position - prey.global_position).normalized()
		push_dir.y = 0.2  # leve componente vertical
		captor_body.velocity = push_dir * 20.0

	print("💔 Penalización aplicada — liberación forzada")

	# Liberar presa → volver a NORMAL
	var prey_state := prey.get_node_or_null("EnemyStateMachine") as EnemyStateMachine
	if prey_state:
		prey_state._change_state(EnemyStateMachine.PhysicalState.NORMAL)

	# Jugador transiciona a STUNNED según NT sección 3.8
	EventBus.emit_event("EVT_LIBERACION_FORZADA_CAPTOR", {
		"target_id": captor.name
	}, {"priority": 10})

func _apply_minor_penalty() -> void:
	var posture_comp := captor.get_node_or_null("PostureComponent")
	if posture_comp and posture_comp.has_method("apply_posture_damage"):
		posture_comp.apply_posture_damage(PENALTY_POSTURE * 0.5)
	print("⚠️ Penalización menor por cancelación")

	var prey_state := prey.get_node_or_null("EnemyStateMachine") as EnemyStateMachine
	if prey_state:
		prey_state._change_state(EnemyStateMachine.PhysicalState.NORMAL)

func _cleanup() -> void:
	captor = null
	prey   = null
	captor_stamina = null
	prey_stamina   = null
	prey_stamina_depleted = false
	capture_combo_index = 0

func reset_capture_combo() -> void:
	if capture_combo_index == 0:
		return
	capture_combo_index = 0
	print("↩️ Combo captura reiniciado")
