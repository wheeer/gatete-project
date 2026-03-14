class_name EntitySnapshot
extends Resource

@export var entity_id: String = ""
@export var timestamp: int = 0
@export var health_current: float = 0.0
@export var health_max: float = 0.0
@export var posture_current: float = 0.0
@export var posture_max: float = 0.0
@export var hearts_current: int = 0
@export var physical_state: String = ""
@export var mental_state: String = ""
@export var psychological_profile: String = ""
@export var is_capturing: bool = false
@export var is_captured: bool = false
@export var grab_stamina_current: float = 0.0
@export var grab_stamina_max: float = 0.0
@export var capture_resistance_current: float = 0.0
@export var capture_resistance_max: float = 0.0
@export var position: Vector3 = Vector3.ZERO
@export var additional: Dictionary = {}
