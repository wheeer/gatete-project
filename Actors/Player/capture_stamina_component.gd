extends Node
class_name CaptureStaminaComponent

signal capture_stamina_changed(current: float, max_val: float)

@export var max_capture_stamina: float = 100.0
@export var capture_resistance: float = 1.0
@export var capture_weight: String = "MEDIO"  # LIVIANO / MEDIO / PESADO
@export var capacidad_forcejeo: String = "MEDIA"  # BAJA / MEDIA / ALTA
## Daño por golpe de forcejeo — será sobreescrito por ADN_Handler en el futuro
@export var forcejeo_damage: float = 8.0

var current_capture_stamina: float

func _ready() -> void:
	current_capture_stamina = max_capture_stamina
	capture_stamina_changed.emit(current_capture_stamina, max_capture_stamina)

func apply_drain(amount: float) -> void:
	if amount <= 0.0:
		return
	current_capture_stamina -= amount
	current_capture_stamina = maxf(0.0, current_capture_stamina)
	capture_stamina_changed.emit(current_capture_stamina, max_capture_stamina)

func reset() -> void:
	current_capture_stamina = max_capture_stamina
	capture_stamina_changed.emit(current_capture_stamina, max_capture_stamina)

func is_depleted() -> bool:
	return current_capture_stamina <= 0.0

func get_capture_stamina() -> float:
	return current_capture_stamina

func get_capture_stamina_max() -> float:
	return max_capture_stamina

func get_capture_resistance() -> float:
	return capture_resistance
