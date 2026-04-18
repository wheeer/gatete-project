# Systems/raza_resource.gd
class_name RazaResource
extends Resource

## Identificación
@export var nombre_raza: String = ""

## === STATS BASE ===
## Distribuidos por ADNHandler a los componentes en el momento del spawn.
## Ningún componente debe leer estos valores directamente — solo ADNHandler los toca.

# HealthComponent
@export var vida_base: float = 100.0

# PostureComponent
@export var postura_base: float = 100.0

# EnemyMovementComponent
@export var velocidad_base: float = 3.5

## === COMBATE ===
# EnemyCombatComponent
@export var damage_base: float = 20.0
@export var posture_damage_base: float = 10.0
@export var attack_cooldown: float = 2.0
@export var detection_range: float = 12.0
@export var attack_range: float = 1.8

## true = esta raza puede ejecutar golpes fuertes (NT §6 / §13)
## Los insectos y presas fáciles siempre en false
@export var can_be_heavy: bool = false

## === CAPTURA ===
# CaptureStaminaComponent
@export var capture_stamina_max: float = 100.0
@export var capture_resistance: float = 1.0
@export var capture_weight: String = "MEDIO"      # LIVIANO / MEDIO / PESADO
@export var capacidad_forcejeo: String = "MEDIA"  # BAJA / MEDIA / ALTA
@export var forcejeo_damage: float = 8.0
