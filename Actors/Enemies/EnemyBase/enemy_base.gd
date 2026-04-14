extends CharacterBody3D
class_name EnemyBase

@onready var health: HealthComponent = $HealthComponent
@onready var posture: PostureComponent = $PostureComponent
@onready var stun: StunComponent = $StunComponent
@onready var movement: EnemyMovementComponent = $EnemyMovementComponent
@onready var combat: EnemyCombatComponent = $EnemyCombatComponent

## Tiempo que el cuerpo permanece visible antes del fade (segundos)
const DEATH_LINGER_TIME: float = 3.5
## Duración del fade de desaparición (segundos)
const DEATH_FADE_TIME: float = 1.0

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
	_begin_death_sequence()

## Secuencia de muerte — cuerpo permanece inerte antes de desaparecer (NT placeholder)
func _begin_death_sequence() -> void:
	# Desactivar toda lógica de juego inmediatamente
	set_process(false)
	set_physics_process(false)

	# Desactivar colisiones para no estorbar a jugador, enemigos ni proyectiles
	var col := get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)

	# [HOOK FUTURO] Aquí se reproducirá la animación de muerte
	# AnimationPlayer.play("death") o similar

	# Esperar antes del fade (tiempo configurable)
	await get_tree().create_timer(DEATH_LINGER_TIME).timeout

	# Fade gradual — reducir alpha del mesh progresivamente
	await _fade_out()

	queue_free()

## Fade gradual del mesh hasta transparencia total
func _fade_out() -> void:
	var mesh : MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mesh == null:
		queue_free()
		return

	var mat : StandardMaterial3D = mesh.material_override
	if mat == null or not mat is StandardMaterial3D:
		queue_free()
		return

	# Habilitar transparencia en el material
	(mat as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var elapsed: float = 0.0
	while elapsed < DEATH_FADE_TIME:
		elapsed += get_process_delta_time()
		var alpha: float = 1.0 - clamp(elapsed / DEATH_FADE_TIME, 0.0, 1.0)
		(mat as StandardMaterial3D).albedo_color.a = alpha
		await get_tree().process_frame

func _spawn_floating_ui() -> void:
	var ui_scene = preload("res://UI/EnemyUI/floating_health_bar.tscn")
	floating_ui = ui_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", floating_ui)
	floating_ui.call_deferred("initialize", self, health, posture)
