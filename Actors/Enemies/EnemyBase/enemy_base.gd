extends CharacterBody3D
class_name EnemyBase

@onready var health: HealthComponent = $HealthComponent
@onready var posture: PostureComponent = $PostureComponent
@onready var stun: StunComponent = $StunComponent
@onready var movement: EnemyMovementComponent = $EnemyMovementComponent
@onready var combat: EnemyCombatComponent = $EnemyCombatComponent

var floating_ui: Node2D
var state_machine: EnemyStateMachine  # ← AÑADE ESTO

func _ready():
	add_to_group("targetable")

	stun.initialize(self)
	movement.initialize(self)
	combat.initialize(self, health, posture)
	
	# ← AÑADE ESTO
	state_machine = EnemyStateMachine.new()
	state_machine.initialize(self)

	health.died.connect(_on_died)

	_spawn_floating_ui()

func set_targeted(value: bool) -> void:
	var marker = $TargetMarker
	if marker:
		marker.visible = value

func _physics_process(delta: float) -> void:
	if stun.is_stunned():
		movement.stop()
		return
		
	movement.physics_process(delta)
func take_damage(_hit_data: Dictionary) -> void:
	# DEPRECATED: Este método no debería usarse.
	# Todo el daño debe pasar por CombatMediator → DamageResolver → EventBus.
	# Si ves este warning, algo está usando el camino viejo.
	push_warning("EnemyBase.take_damage() llamado directamente en: %s — usar CombatMediator" % name)

func _on_died():
	EventBus.emit_event("EVT_ENEMIGO_MUERTO", {
		"target_id": name,
		"position": global_position
	}, {"priority": 10})
	queue_free()

func _spawn_floating_ui() -> void:
	var ui_scene = preload("res://UI/EnemyUI/floating_health_bar.tscn")
	floating_ui = ui_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", floating_ui)
	floating_ui.initialize(self, health, posture)
