extends Node
class_name HealthComponent

signal health_changed(current: float, max: float)
signal died

@export var max_health: float = 150.0

var current_health: float

func _ready() -> void:
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)

func apply_damage(amount: float) -> void:
	if amount <= 0:
		return
	
	current_health -= amount
	current_health = max(current_health, 0)
	
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0:
		call_deferred("emit_signal", "died")

func _emit_died() -> void:
	emit_signal("_emit_died")

func heal(amount: float) -> void:
	if amount <= 0:
		return
	
	current_health += amount
	current_health = min(current_health, max_health)
	
	emit_signal("health_changed", current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0
