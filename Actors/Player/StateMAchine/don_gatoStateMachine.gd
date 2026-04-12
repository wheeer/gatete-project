extends Node
class_name DonGatoStateMachine

@onready var movement_system = $"../MovementSystem"
@onready var combat_system = $"../CombatSystem"
@onready var targeting_system = $"../Targeting"

enum CatState {
	NORMAL,
	ATTACKING,
	DASHING,
	STUNNED,
	POSTURE_BROKEN,
	KNOCKED_AIRBORNE,
	AIR_RECOVERY,
	TIMESTOP,
	CAPTURING
}

const STUN_DURATION: float = 1.5
const TIMESTOP_DURATION: float = 0.35
const AIR_RECOVERY_DURATION: float = 0.3

const PENALTY_HEALTH: float = 15.0
const PENALTY_POSTURE: float = 20.0
const PENALTY_STUN: float = 1.0

var current_state: CatState = CatState.NORMAL
var stun_timer: float = 0.0
var _timestop_timer: float = 0.0
var _air_recovery_timer: float = 0.0
var _pending_push: Vector3 = Vector3.ZERO

func change_state(new_state: CatState) -> void:
	if current_state == new_state:
		return

	# Salir del estado anterior
	match current_state:
		CatState.CAPTURING:
			movement_system.force_free_look = false
			
		CatState.TIMESTOP:
			if get_tree().paused:
				get_tree().paused = false
		CatState.KNOCKED_AIRBORNE:
			
			pass

	current_state = new_state

	# Entrar al nuevo estado
	match current_state:
		CatState.STUNNED:
			movement_system.cancel_dash_state() 
			stun_timer = STUN_DURATION
			print("Don Gato — STUNNED")

		CatState.POSTURE_BROKEN:
			print("Don Gato — POSTURE_BROKEN → transicionando a STUNNED")
			change_state(CatState.STUNNED)

		CatState.KNOCKED_AIRBORNE:
			get_tree().paused = false
			movement_system.cancel_dash_state()  # ← limpiar estado de dash
			var body: CharacterBody3D = movement_system.body as CharacterBody3D
			if body:
				body.velocity.x = _pending_push.x * 22.0
				body.velocity.z = _pending_push.z * 22.0
				body.velocity.y = 8.0
			print("Don Gato — KNOCKED_AIRBORNE")

		CatState.AIR_RECOVERY:
			get_tree().paused = false
			var body: CharacterBody3D = movement_system.body as CharacterBody3D
			if body:
				body.velocity.x *= 0.2
				body.velocity.z *= 0.2
				body.velocity.y = 1.0
			_air_recovery_timer = AIR_RECOVERY_DURATION
			print("Don Gato — AIR_RECOVERY exitoso ✅")

		CatState.CAPTURING:
			movement_system.force_free_look = true

## Entrada especial para TIMESTOP — recibe la dirección del lanzamiento
func enter_timestop(push_dir: Vector3) -> void:
	if current_state == CatState.TIMESTOP:
		return
	_pending_push = push_dir
	_timestop_timer = TIMESTOP_DURATION
	current_state = CatState.TIMESTOP
	get_tree().paused = true
	print("Don Gato — TIMESTOP activado (%.2fs)" % TIMESTOP_DURATION)

func physics_update(delta: float) -> void:
	match current_state:
		CatState.NORMAL:
			var speed_multiplier := 1.0
			if combat_system.is_in_combo_flow():
				speed_multiplier = 0.6
			movement_system.physics_update(delta, speed_multiplier)

		CatState.ATTACKING:
			movement_system.physics_update(delta, 0.5)

		CatState.DASHING:
			movement_system.physics_update(delta)

		CatState.STUNNED:
			movement_system.physics_update(delta, 0.0)
			stun_timer -= delta
			if stun_timer <= 0.0:
				change_state(CatState.NORMAL)

		CatState.TIMESTOP:
			# El árbol está pausado — solo este nodo procesa
			_timestop_timer -= delta
			if _timestop_timer <= 0.0:
				# Tiempo agotado — fallo de AIR_RECOVERY
				print("Don Gato — fallo AIR_RECOVERY ❌")
				change_state(CatState.KNOCKED_AIRBORNE)

		CatState.KNOCKED_AIRBORNE:
			movement_system.physics_only(delta)
			var body: CharacterBody3D = movement_system.body as CharacterBody3D
			if body and body.is_on_floor():
				_apply_airborne_penalty()
				change_state(CatState.STUNNED)

		CatState.AIR_RECOVERY:
			movement_system.physics_update(delta, 0.5)
			_air_recovery_timer -= delta
			if _air_recovery_timer <= 0.0:
				change_state(CatState.NORMAL)

		CatState.CAPTURING:
			var prey: Node = combat_system.capture_resolver.prey
			var current_target: Node = targeting_system.current_target
			if current_target == null or current_target == prey:
				movement_system.force_free_look = true
			else:
				movement_system.force_free_look = false
			var multiplier: float = combat_system.capture_resolver.speed_multiplier
			movement_system.physics_update(delta, multiplier)
			combat_system.update_capture(delta)

		CatState.POSTURE_BROKEN:
			pass

## Devuelve true si el jugador está en una ventana de vulnerabilidad legible.
## Consultado por CombatMediator para evaluar is_heavy_hit en runtime.
func is_vulnerable() -> bool:
	# Estados físicos que implican vulnerabilidad total
	if current_state == CatState.STUNNED:
		return true
	if current_state == CatState.POSTURE_BROKEN:
		return true
	# Ventanas de recovery dentro de estados activos
	if combat_system.is_in_attack_recovery():
		return true
	if combat_system.is_in_whiff():
		return true
	if movement_system.is_in_dash_recovery():
		return true
	return false

func handle_input(event: InputEvent) -> void:
	match current_state:
		CatState.NORMAL:
			movement_system.handle_input(event)
			if event.is_action_pressed("atacar"):
				combat_system.try_attack()
			if event is InputEventMouseButton:
				if event.is_action_pressed("Capturar"):
					combat_system.try_capture()
					if combat_system.is_capturing:
						change_state(CatState.CAPTURING)

		CatState.ATTACKING:
			movement_system.handle_input(event)
			if event.is_action_pressed("atacar"):
				combat_system.try_attack()
			if event.is_action_pressed("rundash"):
				combat_system.cancel_attack()
				change_state(CatState.DASHING)
			if event.is_action_pressed("saltar"):
				combat_system.cancel_attack()
			if event.is_action_pressed("agacharse"):
				combat_system.cancel_attack()

		CatState.TIMESTOP:
			if event.is_action_pressed("rundash"):
				change_state(CatState.AIR_RECOVERY)

		CatState.KNOCKED_AIRBORNE:
			pass

		CatState.CAPTURING:
			if event.is_action_pressed("atacar"):
				var prey: Node = combat_system.capture_resolver.prey
				var current_target: Node = targeting_system.current_target
				if current_target == null or current_target == prey:
					combat_system.capture_resolver.register_hit_on_prey()
				else:
					combat_system.try_attack_during_capture(current_target)
			if event is InputEventMouseButton:
				if event.is_action_released("Capturar"):
					combat_system.cancel_capture_attempt()
					change_state(CatState.NORMAL)

		CatState.DASHING:
			pass

## Penalización por aterrizar sin AIR_RECOVERY (NT §13.3)
func _apply_airborne_penalty() -> void:
	var body_node : CharacterBody3D = movement_system.body
	if body_node == null:
		return

	var health : DonGatoHealth = body_node.get_node_or_null("HealthComponent")
	if health and health.has_method("apply_damage"):
		health.apply_damage(PENALTY_HEALTH)

	var posture : DonGatoPosture = body_node.get_node_or_null("PostureComponent")
	if posture and posture.has_method("apply_posture_damage"):
		posture.apply_posture_damage(PENALTY_POSTURE)

	var lives : DonGatoLives = body_node.get_node_or_null("LivesSystem")
	if lives and lives.has_method("consume_heart"):
		lives.consume_heart()

	stun_timer = PENALTY_STUN
	print("Don Gato — penalización KNOCKED_AIRBORNE aplicada 💔")
	EventBus.emit_event("EVT_FALLO_RECUPERACION", {
		"target_id": body_node.name
	}, {"priority": 10})
