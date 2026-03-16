extends Node
class_name StunComponent

signal state_changed(new_state: StunState)
signal stun_started
signal stun_ended

## NOTA DE ARQUITECTURA:
# Este componente maneja el estado FÍSICO-INTERNO del enemigo (StunState).
# En paralelo, EnemyStateMachine maneja el estado FÍSICO-EXTERNO (PhysicalState).
# Cuando la postura se rompe:
#   → StunComponent cambia a StunState.BROKEN (detiene movimiento internamente)
#   → EnemyStateMachine cambia a PhysicalState.POSTURE_BROKEN (via EVT_POSTURA_ROTA)
# Ambos son necesarios. El StunComponent es la fuente de verdad para el movimiento.
# La StateMachine es la fuente de verdad para la ventana de captura y el EventBus.

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
	posture.posture_recovered.connect(_on_posture_recovered)

func _change_state(new_state: StunState) -> void:
	if new_state == current_state:
		return

	current_state = new_state
	state_changed.emit(new_state)

	match new_state:
		StunState.STUNNED, StunState.BROKEN:
			stun_started.emit()
		StunState.NONE:
			stun_ended.emit()

func _on_posture_broken() -> void:
	_change_state(StunState.BROKEN)

func _on_posture_recovered() -> void:  # ← NUEVO
	_change_state(StunState.NONE)

func is_stunned() -> bool:
	return current_state != StunState.NONE
