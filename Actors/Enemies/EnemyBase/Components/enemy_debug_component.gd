extends Node
class_name EnemyDebugComponent

@onready var enemy: EnemyBase = get_parent()
@onready var health: HealthComponent = $"../HealthComponent"
@onready var posture: PostureComponent = $"../PostureComponent"
@onready var stun: StunComponent = $"../StunComponent"

func _process(_delta: float) -> void:
	if not OS.is_debug_build():
		return
	
	var state: String = enemy.state_machine.get_state_name() if enemy.state_machine != null else "N/A"
	var stun_state = stun.current_state
	
	print(
		"HP:", snapped(health.current_health, 1),
		"| POSTURE:", snapped(posture.current_posture, 1),
		"| STATE:", state,
		"| STUN:", stun_state
	)
