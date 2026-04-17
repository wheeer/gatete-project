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
const AIR_REACTION_WINDOW: float = 0.4

var _air_reaction_timer: float = 0.0
var _air_recovery_attempted: bool = false

const PENALTY_HEALTH: float = 15.0
const PENALTY_POSTURE: float = 20.0
const PENALTY_STUN: float = 1.0

var current_state: CatState = CatState.NORMAL
var stun_timer: float = 0.0
var _timestop_timer: float = 0.0
var _air_recovery_timer: float = 0.0
var _pending_push: Vector3 = Vector3.ZERO

var _original_player_material: Material = null
var _color_locked: bool = false  # si true, solo el controller puede cambiar el color Material = null

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
		CatState.NORMAL:
			_restore_player_material()

		CatState.ATTACKING:
			_set_player_color(Color(1.0, 1.0, 0.0))   # amarillo — startup

		CatState.DASHING:
			_set_player_color(Color(0.0, 1.0, 1.0))   # cyan

		CatState.STUNNED:
			movement_system.cancel_dash_state()
			stun_timer = STUN_DURATION
			_set_player_color(Color(0.5, 0.5, 0.5))   # gris
			print("Don Gato — STUNNED")

		CatState.POSTURE_BROKEN:
			print("Don Gato — POSTURE_BROKEN → transicionando a STUNNED")
			change_state(CatState.STUNNED)

		CatState.KNOCKED_AIRBORNE:
			get_tree().paused = false
			movement_system.cancel_dash_state()
			# Impulso ya fue aplicado en enter_timestop() — no re-aplicar
			_air_reaction_timer = AIR_REACTION_WINDOW
			_air_recovery_attempted = false
			_set_player_color(Color(1.0, 0.4, 0.8))   # rosa
			print("Don Gato — KNOCKED_AIRBORNE (ventana reacción: %.2fs)" % AIR_REACTION_WINDOW)

		CatState.AIR_RECOVERY:
			get_tree().paused = false
			var body: CharacterBody3D = movement_system.body as CharacterBody3D
			if body:
				body.velocity.x *= 0.2
				body.velocity.z *= 0.2
				body.velocity.y = 1.0
			_air_recovery_timer = AIR_RECOVERY_DURATION
			_set_player_color(Color(0.0, 1.0, 0.4))   # verde brillante
			print("Don Gato — AIR_RECOVERY exitoso ✅")

		CatState.CAPTURING:
			movement_system.force_free_look = true
			_set_player_color(Color(0.5, 0.0, 1.0))   # violeta

		CatState.TIMESTOP:
			_set_player_color(Color(1.0, 0.1, 0.1))   # rojo intenso

## Entrada especial para TIMESTOP — recibe la dirección del lanzamiento
func enter_timestop(push_dir: Vector3) -> void:
	if current_state == CatState.TIMESTOP:
		return
	_pending_push = push_dir

	# Aplicar impulso INMEDIATAMENTE — el jugador sale volando ahora
	var body: CharacterBody3D = movement_system.body as CharacterBody3D
	if body:
		body.velocity.x = push_dir.x * 22.0
		body.velocity.z = push_dir.z * 22.0
		body.velocity.y = 8.0

	_timestop_timer = TIMESTOP_DURATION
	current_state = CatState.TIMESTOP
	get_tree().paused = true
	_set_player_color(Color(1.0, 0.1, 0.1))  # rojo intenso — TIMESTOP
	print("Don Gato — TIMESTOP activado (%.2fs) — impulso aplicado" % TIMESTOP_DURATION)

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
				# Sin input — entra en KNOCKED_AIRBORNE (ya tiene impulso aplicado)
				change_state(CatState.KNOCKED_AIRBORNE)

		CatState.KNOCKED_AIRBORNE:
			movement_system.physics_only(delta)
			var body: CharacterBody3D = movement_system.body as CharacterBody3D
			if body == null:
				return

			# Descontar ventana de reacción
			if _air_reaction_timer > 0.0:
				_air_reaction_timer -= delta

			# Detectar colisión con pared u objeto inamovible
			if body.is_on_wall():
				if _air_recovery_attempted:
					# Reaccionó antes del choque — se pega brevemente, sin castigo
					_set_player_color(Color(0.0, 1.0, 0.4))  # verde — salvado
					print("Don Gato — se pegó a la pared con AIR_RECOVERY ✅")
					change_state(CatState.AIR_RECOVERY)
				else:
					# No reaccionó — castigo completo por impacto
					print("Don Gato — impacto con pared ❌")
					_apply_airborne_penalty()
					change_state(CatState.STUNNED)
				return

			# Aterrizó en suelo
			if body.is_on_floor():
				if _air_recovery_attempted:
					# Reaccionó en el aire exitosamente
					change_state(CatState.AIR_RECOVERY)
				else:
					# No reaccionó — castigo completo
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
	# Agotamiento de stamina — movimiento torpe, sin capacidad de reacción 
	if movement_system.stats and movement_system.stats.is_exhausted:
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
			pass

		CatState.KNOCKED_AIRBORNE:
			# Solo se puede reaccionar durante la primera mitad del vuelo
			if event.is_action_pressed("rundash") and _air_reaction_timer > 0.0:
				_air_recovery_attempted = true
				_set_player_color(Color(0.0, 1.0, 0.4))  # verde — reacción registrada
				print("Don Gato — reacción aérea registrada ✅")

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
	
## Feedback visual de estado — placeholder hasta modelo real
## Mismo patrón que enemy_state_machine._set_mesh_color()
## Inicializar material base — llamar una sola vez al inicio
func init_player_material() -> void:
	var body_node: CharacterBody3D = movement_system.body as CharacterBody3D
	if body_node == null:
		return
	var mesh: MeshInstance3D = body_node.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh == null:
		return
	_original_player_material = mesh.material_override

func _set_player_color(color: Color) -> void:
	if _color_locked:
		return
	var body_node: CharacterBody3D = movement_system.body as CharacterBody3D
	if body_node == null:
		return
	var mesh: MeshInstance3D = body_node.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat

## Fuerza un color ignorando el lock — exclusivo para el controller (exhausto)
func force_player_color(color: Color) -> void:
	_color_locked = true
	var body_node: CharacterBody3D = movement_system.body as CharacterBody3D
	if body_node == null:
		return
	var mesh: MeshInstance3D = body_node.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	
## Restaura el material original del mesh del jugador
func _restore_player_material() -> void:
	_color_locked = false
	var body_node: CharacterBody3D = movement_system.body as CharacterBody3D
	if body_node == null:
		return
	var mesh: MeshInstance3D = body_node.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh == null:
		return
	mesh.material_override = _original_player_material
