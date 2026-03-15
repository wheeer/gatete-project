extends Node
class_name DonGatoHealth

signal health_changed(current: float, max_val: float)
signal died

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

## Mismo nombre que el enemigo — el CombatMediator y el SnapshotFactory
## buscan este método en cualquier actor
func apply_damage(amount: float) -> void:
	if amount <= 0:
		return
	
	current_health -= amount
	current_health = maxf(0.0, current_health)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()

func heal(amount: float) -> void:
	if amount <= 0:
		return
	
	current_health += amount
	current_health = minf(current_health, max_health)
	
	emit_signal("health_changed", current_health, max_health)

## Mantenemos get_health() y get_health_max() porque el SnapshotFactory los usa
func get_health() -> float:
	return current_health

func get_health_max() -> float:
	return max_health

func is_alive() -> bool:
	return current_health > 0.0
