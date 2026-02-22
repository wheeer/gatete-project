extends Node
class_name DonGatoMovement

signal jumped
signal dash_started
signal dash_finished

enum LocomotionState {
	IDLE,
	MOVE,
	AIRBORNE
}

var original_mesh_y: float = 0.0
var body: CharacterBody3D
var mesh_root: Node3D   # Nodo que contiene Mesh + hijos visuales
var stats: DonGatoStats
var current_state: LocomotionState = LocomotionState.IDLE
var input_dir: Vector3 = Vector3.ZERO
var is_crouching: bool = false
var is_sprinting: bool = false

# Movimiento
const WALK_SPEED := 8.0
const CROUCH_SPEED := 4.0
const JUMP_VELOCITY := 7.0
const GRAVITY := 20.0
const SPRINT_SPEED := 12.0
const SPRINT_COST_PER_SECOND := 20.0
const EXHAUSTED_SPEED := 4.0

# Escala visual
const NORMAL_SCALE_Y := 1.0
const CROUCH_SCALE_Y := 0.6

func setup(_body: CharacterBody3D, _mesh_root: Node3D, _stats: DonGatoStats) -> void:
	body = _body
	mesh_root = _mesh_root
	stats = _stats
	original_mesh_y = mesh_root.position.y

func physics_update(delta: float, speed_multiplier: float = 1.0) -> void:
	_read_input()
	_update_state()
	_apply_gravity(delta)
	_apply_movement(delta, speed_multiplier)
	body.move_and_slide()
	_update_visuals()
	
func _read_input() -> void:
	is_crouching = Input.is_action_pressed("agacharse")
	is_sprinting = Input.is_action_pressed("correr")

	var input_2d := Vector2(
		Input.get_action_strength("derecha") - Input.get_action_strength("izquierda"),
		Input.get_action_strength("abajo") - Input.get_action_strength("arriba")
	).normalized()
	
	input_dir = Vector3(input_2d.x, 0, input_2d.y)

func _update_state() -> void:
	if not body.is_on_floor():
		current_state = LocomotionState.AIRBORNE
		return
	
	if input_dir != Vector3.ZERO:
		current_state = LocomotionState.MOVE
	else:
		current_state = LocomotionState.IDLE

func _apply_gravity(delta: float) -> void:
	if not body.is_on_floor():
		body.velocity.y -= GRAVITY * delta

func _apply_movement(delta: float, speed_multiplier: float) -> void:
	var speed := WALK_SPEED

	# Prioridad absoluta: agotado
	if stats and stats.is_exhausted:
		speed = EXHAUSTED_SPEED
	
	elif is_crouching:
		speed = CROUCH_SPEED
	
	elif is_sprinting and input_dir != Vector3.ZERO and stats:
		var cost := SPRINT_COST_PER_SECOND * delta
		
		if stats.spend(cost):
			speed = SPRINT_SPEED
		else:
			is_sprinting = false
			speed = WALK_SPEED
			
	speed *= speed_multiplier

	if input_dir != Vector3.ZERO:
		body.velocity.x = move_toward(body.velocity.x, input_dir.x * speed, speed * 5 * delta)
		body.velocity.z = move_toward(body.velocity.z, input_dir.z * speed, speed * 5 * delta)
	else:
		body.velocity.x = move_toward(body.velocity.x, 0, speed * 5 * delta)
		body.velocity.z = move_toward(body.velocity.z, 0, speed * 5 * delta)

func _update_visuals() -> void:
	if mesh_root == null:
		return
	
	var target_scale_y := NORMAL_SCALE_Y
	var target_y := original_mesh_y
	
	if is_crouching:
		target_scale_y = CROUCH_SCALE_Y
		
		# Compensamos visualmente la mitad de la diferencia
		var height_diff := 1.0 - CROUCH_SCALE_Y
		target_y = original_mesh_y - height_diff * 0.5
	
	mesh_root.scale.y = lerp(mesh_root.scale.y, target_scale_y, 10.0 * get_physics_process_delta_time())
	mesh_root.position.y = lerp(mesh_root.position.y, target_y, 10.0 * get_physics_process_delta_time())
	
	var shadow := mesh_root.get_node_or_null("Shadow")
	
	if shadow:
		var shadow_scale := 1.0
		
		if is_crouching:
			shadow_scale = 1.2
		
		shadow.scale.x = lerp(shadow.scale.x, shadow_scale, 10.0 * get_physics_process_delta_time())
		shadow.scale.z = lerp(shadow.scale.z, shadow_scale, 10.0 * get_physics_process_delta_time())

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("saltar") and body.is_on_floor():
		if stats and stats.spend(15.0):
			body.velocity.y = JUMP_VELOCITY
			emit_signal("jumped")
