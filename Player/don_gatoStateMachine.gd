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

func physics_update(delta: float) -> void:
	match current_state:
		CatState.NORMAL:
			movement_system.physics_update(delta)
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
				if combat_system.try_attack():
					change_state(CatState.ATTACKING)
		
		CatState.ATTACKING:
			pass

func change_state(new_state: CatState) -> void:
	current_state = new_state
