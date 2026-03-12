extends Node
class_name StunComponent

signal state_changed(new_state: StunState)
signal stun_started
signal stun_ended

enum StunState {
	NONE,
	STUNNED,
	BROKEN,
	CAPTURED
}

var current_state: StunState = StunState.NONE
var enemy: EnemyBase
var posture: PostureComponent

func initialize(_enemy: EnemyBase) -> void:
	enemy = _enemy
	posture = enemy.posture

	posture.posture_broken.connect(_on_posture_broken)

func _change_state(new_state: StunState) -> void:
	if new_state == current_state:
		return

	current_state = new_state
	emit_signal("state_changed", new_state)

	match new_state:
		StunState.STUNNED, StunState.BROKEN:
			emit_signal("stun_started")
		StunState.NONE:
			emit_signal("stun_ended")

func _on_posture_broken() -> void:
	_change_state(StunState.BROKEN)

func is_stunned() -> bool:
	return current_state != StunState.NONE
