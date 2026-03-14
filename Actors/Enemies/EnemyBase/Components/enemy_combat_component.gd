extends Node
class_name EnemyCombatComponent

var health: HealthComponent
var posture: PostureComponent
var enemy_base: EnemyBase

func initialize(_enemy: EnemyBase, _health: HealthComponent, _posture: PostureComponent) -> void:
	enemy_base = _enemy
	health = _health
	posture = _posture

func receive_hit(hit_data: Dictionary) -> void:
	print("⚠ receive_hit() llamado directamente (debería usar CombatMediator)")
	var damage = hit_data["damage"]
	var strength = hit_data["strength"]

	var multiplier := _get_damage_multiplier()
	var posture_damage := _calculate_posture_damage(strength)

	if hit_data.has("combo_index"):
		match hit_data["combo_index"]:
			2:
				posture_damage *= 1.15
			3:
				posture_damage *= 1.5

	posture.apply_posture_damage(posture_damage)
	health.apply_damage(damage * multiplier)

func _get_damage_multiplier() -> float:
	if posture.is_broken():
		return 1.2

	var ratio = posture.current_posture / posture.max_posture

	if ratio < 0.4:
		return 0.45

	return 0.3

func _calculate_posture_damage(strength: int) -> float:
	match strength:
		0: return randf_range(8, 14)
		1: return randf_range(15, 22)
		2: return randf_range(25, 35)
		3: return randf_range(45, 60)
	return randf_range(8, 14)
