extends Node
class_name DonGatoPosture

signal posture_changed(current: float, max_val: float)
signal posture_broken
signal posture_recovered

@export var max_posture: float = 100.0
@export var recovery_rate: float = 8.0          # enemigo (10.0)
@export var damage_regen_delay: float = 2.0     # enemigo (1.2)
@export var broken_recovery_delay: float = 5.0  # enemigo (3.5)
@export var instant_recovery_ratio: float = 0.4 # enemigo (0.6)

var current_posture: float
var broken: bool = false
var regen_delay_timer: float = 0.0
var broken_timer: float = 0.0

func _ready() -> void:
	current_posture = max_posture
	posture_changed.emit(current_posture, max_posture)

func _process(delta: float) -> void:
	if broken:
		broken_timer += delta
		if broken_timer >= broken_recovery_delay:
			_trigger_recovery()
		return
	
	if regen_delay_timer > 0:
		regen_delay_timer -= delta
		return
	
	if current_posture < max_posture:
		current_posture += recovery_rate * delta
		current_posture = minf(current_posture, max_posture)
		posture_changed.emit(current_posture, max_posture)

## Mismo nombre que el enemigo
func apply_posture_damage(amount: float) -> void:
	if amount <= 0:
		return
	
	regen_delay_timer = damage_regen_delay
	
	if broken:
		return  # si ya está rota, ignorar daño adicional a postura
	
	current_posture -= amount
	current_posture = maxf(0.0, current_posture)
	
	posture_changed.emit(current_posture, max_posture)
	
	if current_posture <= 0:
		broken = true
		broken_timer = 0.0
		posture_broken.emit()

func is_broken() -> bool:
	return broken

func is_regenerating() -> bool:
	return regen_delay_timer <= 0 and not broken

## Para el SnapshotFactory
func get_posture() -> float:
	return current_posture

func get_posture_max() -> float:
	return max_posture

func _trigger_recovery() -> void:
	current_posture = max_posture * instant_recovery_ratio
	broken = false
	broken_timer = 0.0
	posture_changed.emit(current_posture, max_posture)
	posture_recovered.emit()
