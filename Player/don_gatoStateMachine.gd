extends Node

class_name DonGatoStateMachine

@onready var movement_system = $"../MovementSystem"
@onready var combat_system = $"../CombatSystem"

enum CatState {
	NORMAL,
	ATTACKING,
	DASHING,
	STUNNED,
	POSTURE_BROKEN,
	TIMESTOP
}

var current_state: CatState = CatState.NORMAL

func change_state(new_state: CatState) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
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
			pass
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
		CatState.ATTACKING:
			movement_system.handle_input(event)
			
			if event.is_action_pressed("atacar"):
				combat_system.try_attack()
			
			if event.is_action_pressed("dash"):
				combat_system.cancel_attack()
				change_state(CatState.DASHING)
			
			if event.is_action_pressed("saltar"):
				combat_system.cancel_attack()
				
			if event.is_action_pressed("agacharse"):
				combat_system.cancel_attack()
