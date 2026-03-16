extends Node
class_name EnemyDebugComponent

@onready var enemy: EnemyBase = get_parent()
@onready var health: HealthComponent = $"../HealthComponent"
@onready var posture: PostureComponent = $"../PostureComponent"
@onready var stun: StunComponent = $"../StunComponent"

var _debug_timer: float = 0.0
const DEBUG_INTERVAL: float = 1.0 

func _process(delta: float) -> void:
	if not OS.is_debug_build():
		return
	
	_debug_timer += delta
	if _debug_timer < DEBUG_INTERVAL:
		return
	_debug_timer = 0.0
	
	var state: String = enemy.state_machine.get_state_name() if enemy.state_machine != null else "N/A"
	var stun_state: String = StunComponent.StunState.keys()[stun.current_state]
	
	print("[DEBUG %s] HP:%.0f | POSTURE:%.0f | STATE:%s | STUN:%s" % [
		enemy.name,
		health.current_health,
		posture.current_posture,
		state,
		stun_state
	])
