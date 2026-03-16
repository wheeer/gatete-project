extends Node
class_name PostureComponent

signal posture_changed(current: float, max: float)
signal posture_broken
signal posture_recovered

@export var max_posture: float = 100.0
@export var recovery_rate: float = 10.0
@export var broken_recovery_delay: float = 3.5
@export var instant_recovery_ratio: float = 0.6
@export var damage_regen_delay: float = 1.2

var regen_delay_timer: float = 0.0
var broken_timer: float = 0.0
var recovering: bool = false
var current_posture: float
var broken: bool = false

func _ready() -> void:
	current_posture = max_posture
	posture_changed.emit(current_posture, max_posture)

func _process(delta: float) -> void:
	if broken:
		if not recovering:
			broken_timer += delta
			if broken_timer >= broken_recovery_delay:
				_trigger_instant_recovery()
		return

	if regen_delay_timer > 0:
		regen_delay_timer -= delta
		return

	if current_posture < max_posture:
		current_posture += recovery_rate * delta
		current_posture = min(current_posture, max_posture)
		posture_changed.emit(current_posture, max_posture)

func apply_posture_damage(amount: float) -> void:
	if amount <= 0:
		return

	regen_delay_timer = damage_regen_delay

	if broken:
		broken_timer = 0.0
		return

	current_posture -= amount
	current_posture = max(current_posture, 0)
	posture_changed.emit(current_posture, max_posture)

	if current_posture <= 0:
		broken = true
		recovering = false
		broken_timer = 0.0
		posture_broken.emit()

func is_regenerating() -> bool:
	return regen_delay_timer <= 0 and not broken

func is_broken() -> bool:
	return broken

func get_posture() -> float:
	return current_posture

func get_posture_max() -> float:
	return max_posture

func _trigger_instant_recovery() -> void:
	current_posture = max_posture * instant_recovery_ratio
	broken = false
	recovering = false
	broken_timer = 0.0
	posture_changed.emit(current_posture, max_posture)
	posture_recovered.emit()
