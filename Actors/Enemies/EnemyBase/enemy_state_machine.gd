class_name EnemyStateMachine
extends Node

enum PhysicalState {
	NORMAL,
	STUNNED,
	POSTURE_BROKEN,
	CAPTURED,
	DEAD
}

var current_state: PhysicalState = PhysicalState.NORMAL
var enemy: EnemyBase

func initialize(_enemy: EnemyBase) -> void:
	enemy = _enemy
	# Suscribirse a eventos del EventBus
	EventBus.event_emitted.connect(_on_event_emitted)
	enemy.stun.stun_ended.connect(_on_stun_ended)

func _on_event_emitted(event_id: String, payload: Dictionary, _metadata: Dictionary) -> void:
	# Solo procesar eventos para este enemigo
	var target_id: String = payload.get("target_id", "")
	if target_id != enemy.name:
		return
	
	match event_id:
		"EVT_POSTURA_ROTA":
			_change_state(PhysicalState.POSTURE_BROKEN)
			print("🔴 %s entra en POSTURA_ROTA" % enemy.name)
		
		"EVT_RECIBIR_GOLPE":
			# Posiblemente generar impulsos psicológicos
			pass
		
		"EVT_GOLPE_CRITICO_RECIBIDO":
			# Impulso de PANICO o IRA
			pass
			
		"EVT_ENEMIGO_MUERTO":
			_change_state(PhysicalState.DEAD)
			print("💀 %s entra en DEAD" % enemy.name)

func _on_stun_ended() -> void:
	# Solo volver a NORMAL si no está muerto ni capturado
	if current_state != PhysicalState.DEAD and current_state != PhysicalState.CAPTURED:
		_change_state(PhysicalState.NORMAL)
		print("🟢 %s recupera postura → NORMAL" % enemy.name)

func _change_state(new_state: PhysicalState) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	
	match current_state:
		PhysicalState.POSTURE_BROKEN:
			enemy.movement.stop()
			# TODO: Iniciar animación de caída
			# TODO: Abrir ventana de captura
		
		PhysicalState.STUNNED:
			enemy.movement.stop()
			# TODO: Stun visual
		
		PhysicalState.NORMAL:
			# TODO: Recuperación
			pass
			
		PhysicalState.DEAD:
			enemy.movement.stop()
			if EventBus.event_emitted.is_connected(_on_event_emitted):
				EventBus.event_emitted.disconnect(_on_event_emitted)
			# queue_free es llamado por enemy_base.die()
			
func is_in_state(state: PhysicalState) -> bool:
	return current_state == state

func get_state_name() -> String:
	return PhysicalState.keys()[current_state]
