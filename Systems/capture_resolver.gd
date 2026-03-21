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

func start_capture(_captor: Node, _prey: Node) -> bool:
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

	# Transiciones de estado físico
	EventBus.emit_event("EVT_INTENTO_CAPTURA", {
		"captor_id": captor.name,
		"prey_id":   prey.name
	}, {"priority": 10})

	print("🐱 Captura iniciada: %s → %s" % [captor.name, prey.name])
	var prey_state := prey.get_node_or_null("StateMachine") as EnemyStateMachine
	if prey_state:
		prey_state._change_state(EnemyStateMachine.PhysicalState.CAPTURED)
	return true

func update(delta: float) -> void:
	if not is_active:
		return

	# Drenaje pasivo por tiempo
	captor_stamina.apply_drain(DRAIN_PER_SECOND_CAPTOR * delta)
	prey_stamina.apply_drain(DRAIN_PER_SECOND_PREY * prey_stamina.capture_resistance * delta)

	# Evaluar condiciones de fin (orden del NT §17.5.1)
	if captor_stamina.is_depleted():
		_resolve_verdict("FALLO")
	elif prey_stamina.is_depleted():
		_resolve_verdict("EXITO")


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

	print("💔 Penalización aplicada al captor")

	# Liberar a la presa
	var prey_state := prey.get_node_or_null("StateMachine") as EnemyStateMachine
	if prey_state:
		prey_state._change_state(EnemyStateMachine.PhysicalState.NORMAL)


func _apply_minor_penalty() -> void:
	var posture_comp := captor.get_node_or_null("PostureComponent")
	if posture_comp and posture_comp.has_method("apply_posture_damage"):
		posture_comp.apply_posture_damage(PENALTY_POSTURE * 0.5)
	print("⚠️ Penalización menor por cancelación")

	var prey_state := prey.get_node_or_null("StateMachine") as EnemyStateMachine
	if prey_state:
		prey_state._change_state(EnemyStateMachine.PhysicalState.NORMAL)

func _cleanup() -> void:
	captor = null
	prey   = null
	captor_stamina = null
	prey_stamina   = null
