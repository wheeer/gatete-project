# Actors/Enemies/EnemyBase/adn_handler.gd
class_name ADNHandler
extends Node

## SOLO TESTING — asignar desde el inspector para probar sin spawner.
## En producción el spawner llama initialize() directamente.
## Nunca usar ambos al mismo tiempo.
@export var raza_override: RazaResource = null

var _raza: RazaResource = null

func _ready() -> void:
	if raza_override != null:
		initialize(raza_override)

## Único punto de entrada canónico.
## Llamar ANTES de que EnemyBase._ready() termine,
## o inmediatamente después del spawn antes de que el enemigo procese su primer frame.
func initialize(raza: RazaResource) -> void:
	if raza == null:
		push_error("ADNHandler '%s': initialize() recibió raza null" % get_parent().name)
		return
	_raza = raza
	_distribute()

func _distribute() -> void:
	var enemy := get_parent()

	# --- HealthComponent ---
	var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health:
		health.reset_to_max(_raza.vida_base)
		health.current_health	= _raza.vida_base
	else:
		push_error("ADNHandler '%s': no encontró HealthComponent" % enemy.name)

	# --- PostureComponent ---
	var posture := enemy.get_node_or_null("PostureComponent") as PostureComponent
	if posture:
		posture.reset_to_max(_raza.postura_base)
		posture.current_posture = _raza.postura_base
	else:
		push_error("ADNHandler '%s': no encontró PostureComponent" % enemy.name)

	# --- EnemyMovementComponent ---
	var movement := enemy.get_node_or_null("EnemyMovementComponent") as EnemyMovementComponent
	if movement:
		movement.move_speed = _raza.velocidad_base
	else:
		push_error("ADNHandler '%s': no encontró EnemyMovementComponent" % enemy.name)

	# --- EnemyCombatComponent ---
	var combat := enemy.get_node_or_null("EnemyCombatComponent") as EnemyCombatComponent
	if combat:
		combat.damage_base         = _raza.damage_base
		combat.posture_damage_base = _raza.posture_damage_base
		combat.attack_cooldown     = _raza.attack_cooldown
		combat.detection_range     = _raza.detection_range
		combat.attack_range        = _raza.attack_range
		combat.can_be_heavy        = _raza.can_be_heavy
	else:
		push_error("ADNHandler '%s': no encontró EnemyCombatComponent" % enemy.name)

	# --- CaptureStaminaComponent ---
	var cap := enemy.get_node_or_null("CaptureStaminaComponent") as CaptureStaminaComponent
	if cap:
		cap.max_capture_stamina     = _raza.capture_stamina_max
		cap.current_capture_stamina = _raza.capture_stamina_max
		cap.capture_resistance      = _raza.capture_resistance
		cap.capture_weight          = _raza.capture_weight
		cap.capacidad_forcejeo      = _raza.capacidad_forcejeo
		cap.forcejeo_damage         = _raza.forcejeo_damage
	else:
		push_error("ADNHandler '%s': no encontró CaptureStaminaComponent" % enemy.name)

	print("ADNHandler '%s' — raza '%s' distribuida ✅" % [enemy.name, _raza.nombre_raza])

## Getter de solo lectura — para que otros sistemas consulten la raza activa
## sin poder modificarla directamente
func get_raza() -> RazaResource:
	return _raza
