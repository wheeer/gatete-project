extends CharacterBody3D

class_name DonGatoController

# =========================
# === REFERENCIAS SISTEMA ===
# =========================
@onready var state_machine = $StateMachine
@onready var movement_system = $MovementSystem
@onready var combat_system = $CombatSystem
@onready var stats_system = $StaminaComponent
@onready var targeting_system = $Targeting
@onready var posture_component: DonGatoPosture = $PostureComponent
@onready var lives_system: DonGatoLives = $LivesSystem
@onready var health_component: DonGatoHealth = $HealthComponent

func _ready() -> void:
	add_to_group("Player")
	combat_system.setup(self, $AttackArea, stats_system)
	movement_system.setup(self, $MeshInstance3D, stats_system, targeting_system)
	targeting_system.setup(self)
	combat_system.attack_finished.connect(_on_attack_finished)
	combat_system.attack_started.connect(_on_attack_started)
	movement_system.jumped.connect(_on_jumped)
	movement_system.dash_started.connect(_on_dash_started)
	movement_system.dash_finished.connect(_on_dash_finished)
	posture_component.posture_broken.connect(_on_posture_broken)
	posture_component.posture_recovered.connect(_on_posture_recovered)
	combat_system.capture_resolver.capture_resolved.connect(_on_capture_resolved)
	EventBus.event_emitted.connect(_on_event_emitted)
	# Conectar muerte del jugador
	health_component.died.connect(_on_player_died)
	# Barra de stamina flotante
	var stamina_bar_scene := preload("res://UI/PlayerUI/player_stamina_bar.tscn")
	var stamina_bar_ui := stamina_bar_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", stamina_bar_ui)
	stamina_bar_ui.call_deferred("initialize", self, stats_system)
	print("Don Gato inicializado correctamente ")

func _physics_process(delta: float) -> void:
	# El controller delega la lógica de estado
	state_machine.physics_update(delta)
	targeting_system.physics_update()

func _input(event: InputEvent) -> void:
	
	# Delegamos input a la máquina de estados
	state_machine.handle_input(event)
	targeting_system.handle_input(event)

func _on_jumped() -> void:
	pass
	
func _on_attack_started() -> void:
	state_machine.change_state(state_machine.CatState.ATTACKING)
	
func _on_attack_finished() -> void:
	state_machine.change_state(state_machine.CatState.NORMAL)
	
func _on_dash_started() -> void:
	# Si estamos capturando, el dash no interrumpe la captura
	if state_machine.current_state == state_machine.CatState.CAPTURING:
		return
	state_machine.change_state(state_machine.CatState.DASHING)
	
func _on_dash_finished() -> void:
	if state_machine.current_state == state_machine.CatState.CAPTURING:
		return
	state_machine.change_state(state_machine.CatState.NORMAL)
	
func _on_player_died() -> void:
	# TODO: Bloque 3 del MVP — implementar Game Over / Respawn completo
	# Por ahora bloqueamos inputs para evitar estado indefinido
	state_machine.change_state(state_machine.CatState.STUNNED)
	print("Don Gato ha muerto — pendiente: Game Over / Respawn")
	
func _on_posture_broken() -> void:
	state_machine.change_state(state_machine.CatState.POSTURE_BROKEN)
	print("Don Gato — POSTURA ROTA")

func _on_posture_recovered() -> void:
	state_machine.change_state(state_machine.CatState.NORMAL)
	print("Don Gato — postura recuperada")

func is_capturing() -> bool:
	return combat_system.is_capturing

func is_captured() -> bool:
	return false

func _on_capture_resolved(_result: String) -> void:
	# Solo volver a NORMAL si fue éxito o cancelación
	# En FALLO el estado ya fue puesto a STUNNED por EVT_LIBERACION_FORZADA_CAPTOR
	if _result != "FALLO":
		state_machine.change_state(state_machine.CatState.NORMAL)

func _on_event_emitted(event_id: String, payload: Dictionary, _metadata: Dictionary) -> void:
	if event_id != "EVT_LIBERACION_FORZADA_CAPTOR":
		return
	if payload.get("target_id", "") != name:
		return
	# fallo de captura → STUNNED
	state_machine.change_state(state_machine.CatState.STUNNED)
	print("Don Gato — STUNNED por liberación forzada")
