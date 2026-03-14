extends Node

var posture: float = 0.0
var max_posture: float = 100.0

func _ready() -> void:
	# Inicializa postura al máximo
	posture = max_posture
	print("Posture initialized: %.1f / %.1f" % [posture, max_posture])

func _process(_delta: float) -> void:
	pass

func take_posture_damage(damage: float) -> void:
	posture = maxf(0.0, posture - damage)
	print("Posture damage: %.1f | Posture now: %.1f / %.1f" % [damage, posture, max_posture])
	if posture == 0.0:
		print("Posture broken!")

func restore_posture(amount: float) -> void:
	posture = minf(max_posture, posture + amount)
	print("Posture restored: %.1f | Posture now: %.1f / %.1f" % [amount, posture, max_posture])

func is_posture_broken() -> bool:
	return posture == 0.0

func get_posture() -> float:
	return posture

func get_posture_max() -> float:
	return max_posture
