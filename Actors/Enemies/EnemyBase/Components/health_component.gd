extends Node
class_name HealthComponent

signal health_changed(current: float, max: float)
signal died

@export var max_health: float = 150.0
var current_health: float

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func apply_damage(amount: float) -> void:
	if amount <= 0:
		return
	
	current_health -= amount
	current_health = max(current_health, 0)
	
	health_changed.emit(current_health, max_health)

func heal(amount: float) -> void:
	if amount <= 0:
		return
	
	current_health += amount
	current_health = min(current_health, max_health)
	
	health_changed.emit(current_health, max_health)

func is_dead() -> bool:
	return current_health <= 0
