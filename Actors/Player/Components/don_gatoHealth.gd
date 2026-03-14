extends Node

var health: float = 0.0
var max_health: float = 100.0

func _ready() -> void:
	# Inicializa salud al máximo
	health = max_health
	print("Health initialized: %.1f / %.1f" % [health, max_health])

func _process(_delta: float) -> void:
	pass

func is_alive() -> bool:
	return health > 0.0

func take_damage(damage: float) -> void:
	health = maxf(0.0, health - damage)
	print("Damage taken: %.1f | Health now: %.1f / %.1f" % [damage, health, max_health])
	if not is_alive():
		print("Don Gato has died!")

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	print("Healed: %.1f | Health now: %.1f / %.1f" % [amount, health, max_health])

func get_health() -> float:
	return health

func get_health_max() -> float:
	return max_health
