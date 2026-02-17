extends Node
class_name DonGatoHealth

signal health_changed(current: float, max: float)
signal died
signal damaged(amount: float)

@export var max_health: float = 100.0
@export var invulnerability_time: float = 0.3

var health: float
var invulnerable: bool = false
var invul_timer: float = 0.0

func _ready() -> void:
	health = max_health
	emit_signal("health_changed", health, max_health)

func _physics_process(delta: float) -> void:
	if invulnerable:
		invul_timer -= delta
		if invul_timer <= 0:
			invulnerable = false

func is_alive() -> bool:
	return health > 0.0
	
func take_damage(amount: float) -> void:
	if invulnerable:
		return
	
	health -= amount
	health = max(health, 0.0)
	
	emit_signal("damaged", amount)
	emit_signal("health_changed", health, max_health)
	
	if health <= 0.0:
		emit_signal("died")
	else:
		invulnerable = true
		invul_timer = invulnerability_time

func heal(amount: float) -> void:
	if health <= 0.0:
		return
	
	health += amount
	health = clamp(health, 0.0, max_health)
	emit_signal("health_changed", health, max_health)
