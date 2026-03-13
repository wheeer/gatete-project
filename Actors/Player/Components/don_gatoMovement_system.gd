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
var targeting_system: DonGatoTargeting
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

# Rundash
const DASH_SPEED := 18.0
const DASH_DURATION := 0.18
const DASH_COST := 20.0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

var dash_tap_threshold := 0.18
var dash_input_timer := 0.0
var dash_pressed := false

func setup(_body: CharacterBody3D, _mesh_root: Node3D, _stats: DonGatoStats, _targeting: DonGatoTargeting) -> void:
	body = _body
	mesh_root = _mesh_root
	stats = _stats
	targeting_system = _targeting
	original_mesh_y = mesh_root.position.y

func physics_update(delta: float, speed_multiplier: float = 1.0) -> void:
	_read_input()
	_handle_rundash_input(delta)
	_update_state()
	_apply_gravity(delta)
	_apply_movement(delta, speed_multiplier)
	body.move_and_slide()
	_update_visuals()
	
func _read_input() -> void:
	is_crouching = Input.is_action_pressed("agacharse")
	
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

func _handle_rundash_input(delta: float) -> void:
	if Input.is_action_just_pressed("rundash"):
		dash_pressed = true
		dash_input_timer = 0.0
	
	if dash_pressed:
		dash_input_timer += delta
	
	if Input.is_action_just_released("rundash"):
		if dash_input_timer <= dash_tap_threshold:
			_attempt_dash()
		dash_pressed = false
	
	# Si lo mantiene y se mueve → sprint
	is_sprinting = Input.is_action_pressed("rundash") and input_dir != Vector3.ZERO

func _attempt_dash() -> void:
	if is_dashing:
		return
	
	if not stats or not stats.spend(DASH_COST):
		return
	
	is_dashing = true
	dash_timer = DASH_DURATION
	
	if input_dir != Vector3.ZERO:
		dash_direction = input_dir.normalized()
	else:
		dash_direction = -body.transform.basis.z.normalized()
	
	emit_signal("dash_started")

func _apply_gravity(delta: float) -> void:
	if not body.is_on_floor():
		body.velocity.y -= GRAVITY * delta

func _apply_movement(delta: float, speed_multiplier: float) -> void:
	var speed := WALK_SPEED
	
	if is_dashing:
		dash_timer -= delta
		
		body.velocity.x = dash_direction.x * DASH_SPEED
		body.velocity.z = dash_direction.z * DASH_SPEED
		
		if dash_timer <= 0:
			is_dashing = false
			emit_signal("dash_finished")
		
		return
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
		
		if not targeting_system.is_locked_on():
			var look_dir = input_dir.normalized()
			body.look_at(body.global_position + look_dir, Vector3.UP)
		
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
