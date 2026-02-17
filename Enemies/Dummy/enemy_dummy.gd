extends CharacterBody3D

@export var max_health: float = 10000.0
var health: float

func _ready() -> void:
	health = max_health

func take_damage(amount: float) -> void:
	health -= amount
	print("Enemy recibió daño:", amount, " Vida restante:", health)
	
	if health <= 0:
		print("Enemy muerto")
		queue_free()
