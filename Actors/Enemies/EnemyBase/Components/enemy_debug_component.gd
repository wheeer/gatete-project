extends Node
class_name EnemyDebugComponent

var enemy: EnemyBase
var health: HealthComponent
var posture: PostureComponent
var stun: StunComponent

var _debug_timer: float = 0.0
const DEBUG_INTERVAL: float = 1.0

func _ready() -> void:
	enemy = get_parent() as EnemyBase
	if enemy == null:
		push_error("EnemyDebugComponent: el padre no es EnemyBase")
		return
	health  = enemy.get_node_or_null("HealthComponent")
	posture = enemy.get_node_or_null("PostureComponent")
	stun    = enemy.get_node_or_null("StunComponent")

func _process(delta: float) -> void:
	if not OS.is_debug_build():
		return
	if enemy == null or health == null or posture == null or stun == null:
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
