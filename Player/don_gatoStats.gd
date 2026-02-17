extends Node
class_name DonGatoStats

signal stamina_changed(current: float, max: float)
signal stamina_depleted

# --- Configuración base ---
@export var stamina_max: float = 100.0
@export var stamina_regen_idle: float = 12.0   # fuera de combate (futuro)
@export var stamina_regen_combat: float = 6.0  # en combate (futuro)
@export var stamina_recovery_delay: float = 1.2
# --- Estado interno ---
var stamina: float
var in_combat: bool = false
var recovery_timer: float = 0.0
var is_exhausted: bool = false

func _ready() -> void:
	stamina = stamina_max
	stamina_changed.connect(_debug_print)
	emit_signal("stamina_changed", stamina, stamina_max)

func _debug_print(current: float, _max: float) -> void:
	print("Stamina:", snapped(current, 0.1))

func _physics_process(delta: float) -> void:
	_regenerate(delta)

func _regenerate(delta: float) -> void:
	
	if Input.is_action_pressed("correr"):
		return
	# Si está exhausto, esperar
	if is_exhausted:
		recovery_timer -= delta
		
		if recovery_timer > 0:
			return
		
		if stamina >= 0.0:
			is_exhausted = false
	
	if stamina >= stamina_max:
		return
	
	var regen_rate := stamina_regen_idle
	
	if in_combat:
		regen_rate = stamina_regen_combat
	
	stamina += regen_rate * delta
	stamina = min(stamina, stamina_max)

	
	emit_signal("stamina_changed", stamina, stamina_max)

func can_spend(amount: float) -> bool:
	return not is_exhausted


func spend(amount: float) -> bool:
	if is_exhausted:
		return false
	
	stamina -= amount
	var min_stamina := - (stamina_max * 0.3)
	stamina = max(stamina, min_stamina)

	if stamina < 0.0:
		_trigger_exhaustion()
	
	emit_signal("stamina_changed", stamina, stamina_max)
	return true

func _trigger_exhaustion() -> void:
	is_exhausted = true
	recovery_timer = stamina_recovery_delay
	emit_signal("stamina_depleted")

func recover(amount: float) -> void:
	stamina += amount
	stamina = clamp(stamina, 0.0, stamina_max)
	emit_signal("stamina_changed", stamina, stamina_max)
func set_combat_state(value: bool) -> void:
	in_combat = value
