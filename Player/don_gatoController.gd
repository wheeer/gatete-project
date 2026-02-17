extends CharacterBody3D

class_name DonGatoController

# =========================
# === REFERENCIAS SISTEMA ===
# =========================
@onready var state_machine = $StateMachine
@onready var movement_system = $MovementSystem
@onready var combat_system = $CombatSystem
@onready var posture_system = $PostureSystem
@onready var lives_system = $LivesSystem
@onready var stats_system = $PlayerStats

func _ready() -> void:
	
	movement_system.setup(self, $MeshInstance3D, stats_system)
	combat_system.setup(self, $AttackArea, stats_system)

	# Conexiones de señales Movement
	movement_system.jumped.connect(_on_jumped)
	movement_system.dash_started.connect(_on_dash_started)
	movement_system.dash_finished.connect(_on_dash_finished)
	
	print("Don Gato inicializado correctamente ")

func _physics_process(delta: float) -> void:
	
	# El controller delega la lógica de estado
	state_machine.physics_update(delta)

func _input(event: InputEvent) -> void:
	
	# Delegamos input a la máquina de estados
	state_machine.handle_input(event)

func _on_jumped() -> void:
	pass

func _on_dash_started() -> void:
	state_machine.change_state(state_machine.CatState.DASHING)

func _on_dash_finished() -> void:
	state_machine.change_state(state_machine.CatState.NORMAL)
