extends Node
class_name HeavyHitComponent

@export var heavy_hit_chance: float = 0.20       # 20% por ataque
@export var heavy_hit_cooldown: float = 8.0      # mínimo 8s entre golpes fuertes
@export var impulse_strength: float = 12.0       # fuerza horizontal del lanzamiento
@export var impulse_vertical: float = 6.0        # fuerza vertical del lanzamiento

var _is_on_cooldown: bool = false
var _cooldown_timer: float = 0.0

func _process(delta: float) -> void:
	if _is_on_cooldown:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_is_on_cooldown = false

## Evalúa si este ataque debe ser fuerte — consultar antes de atacar
func can_heavy_hit() -> bool:
	if _is_on_cooldown:
		return false
	return randf() < heavy_hit_chance

## Registrar que se usó — inicia cooldown
func consume() -> void:
	_is_on_cooldown = true
	_cooldown_timer = heavy_hit_cooldown
	print("💥 HeavyHit activado — cooldown %.1fs" % heavy_hit_cooldown)
