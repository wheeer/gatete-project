extends CharacterBody3D
class_name EnemyBase

@onready var health: HealthComponent = $HealthComponent
@onready var posture: PostureComponent = $PostureComponent
@onready var stun: StunComponent = $StunComponent
@onready var movement: EnemyMovementComponent = $EnemyMovementComponent
@onready var combat: EnemyCombatComponent = $EnemyCombatComponent

var state_machine: EnemyStateMachine
var floating_ui: Node2D

func _ready() -> void:
	add_to_group("targetable")

	stun.initialize(self)
	movement.initialize(self)
	combat.initialize(self, health, posture)

	state_machine = get_node_or_null("EnemyStateMachine") as EnemyStateMachine
	if state_machine == null:
		push_error("EnemyBase '%s': no se encontró nodo 'EnemyStateMachine' — verifica el nombre en la escena" % name)
		return
	state_machine.initialize(self)

	_spawn_floating_ui()

func set_targeted(value: bool) -> void:
	var marker = $TargetMarker
	if marker:
		marker.visible = value

func _physics_process(_delta: float) -> void:
	if stun.is_stunned():
		movement.stop()
		return
	movement.physics_process(_delta)

func take_damage(_hit_data: Dictionary) -> void:
	push_warning("EnemyBase.take_damage() llamado directamente en: %s — usar CombatMediator" % name)

func die() -> void:
	EventBus.emit_event("EVT_ENEMIGO_MUERTO", {
		"target_id": name,
		"position": global_position
	}, {"priority": 10})
	queue_free()

func _spawn_floating_ui() -> void:
	var ui_scene = preload("res://UI/EnemyUI/floating_health_bar.tscn")
	floating_ui = ui_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", floating_ui)
	floating_ui.call_deferred("initialize", self, health, posture)
