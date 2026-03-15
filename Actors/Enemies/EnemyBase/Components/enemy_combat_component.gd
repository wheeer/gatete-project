extends Node
class_name EnemyCombatComponent

var health: HealthComponent
var posture: PostureComponent
var enemy_base: EnemyBase

func initialize(_enemy: EnemyBase, _health: HealthComponent, _posture: PostureComponent) -> void:
	enemy_base = _enemy
	health = _health
	posture = _posture

## ATENCIÓN: este método NO debe ser llamado directamente.
## El flujo correcto es CombatMediator → DamageResolver → _apply_verdict_to_entity.
## Si ves este error, revisa quién está llamando receive_hit() en lugar de usar CombatMediator.
func receive_hit(_hit_data: Dictionary) -> void:
	push_error("EnemyCombatComponent.receive_hit() llamado directamente en '%s'. Usar CombatMediator.process_player_attack() en su lugar." % enemy_base.name)
