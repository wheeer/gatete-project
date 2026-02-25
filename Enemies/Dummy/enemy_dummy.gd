extends CharacterBody3D

@export var max_health: float = 50.0
var health: float

func _ready() -> void:
	add_to_group("targetable")
	health = max_health

func set_targeted(value: bool) -> void:
	var marker = $TargetMarker
	if marker:
		marker.visible = value
		
func take_damage(amount: float) -> void:
	health -= amount
	print("Enemy recibió daño:", amount, " Vida restante:", health)
	
	if health <= 0:
		print("Enemy muerto")
		queue_free()
