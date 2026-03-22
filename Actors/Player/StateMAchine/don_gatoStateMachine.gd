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
	TIMESTOP,
	CAPTURING
}

const STUN_DURATION: float = 1.5

var current_state: CatState = CatState.NORMAL
var stun_timer: float = 0.0

func change_state(new_state: CatState) -> void:
	if current_state == new_state:
		return

	if current_state == CatState.CAPTURING:
		movement_system.force_free_look = false

	current_state = new_state

	if current_state == CatState.CAPTURING:
		movement_system.force_free_look = true

	# Iniciar timer al entrar en STUNNED
	if current_state == CatState.STUNNED:
		stun_timer = STUN_DURATION
	
	
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
			if stun_timer > 0.0:
				stun_timer -= delta
			else:
				change_state(CatState.NORMAL)

		CatState.CAPTURING:
			# Actualizar force_free_look según el target actual
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

		CatState.TIMESTOP:
			pass

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
