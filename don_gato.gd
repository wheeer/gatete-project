extends CharacterBody3D

# --- MOVIMIENTO ---
const WALK_SPEED := 4.0
const RUN_SPEED := 8.0
const CROUCH_SPEED := 1.5     

# --- SALTO ---
const JUMP_VELOCITY := 7.0
const GRAVITY_JUMP := 14.0
const GRAVITY_FALL := 28.0
const JUMP_CUT_MULT := 0.4

# --- DASH ---
const DASH_SPEED := 16.0
const DASH_TIME := 0.12
const DASH_COOLDOWN := 0.05
var dash_timer := 0.0
var dash_cooldown := 0.0
var is_dashing := false
var dash_direction := Vector3.ZERO

# --- CORRER / AGACHAR ---
var is_running := false
var is_crouching := false

func _physics_process(delta: float) -> void:
	# --- INPUT MOVIMIENTO ---
	var input_2d = Vector2(
		Input.get_action_strength("derecha") - Input.get_action_strength("izquierda"),
		Input.get_action_strength("abajo") - Input.get_action_strength("arriba")
	).normalized()
	var direction = Vector3(input_2d.x, 0, input_2d.y)

	#  CONTROL DE AGACHAR (CTRL)
	is_crouching = Input.is_action_pressed("acechar")
	if is_crouching:
		is_running = false   # si te agachas, no corres jamás

	# SHIFT: DASH INMEDIATO + CORRER AL MANTENER
	# correr mientras no esté agachado
	if Input.is_action_pressed("run_dash") and not is_crouching:
		is_running = true

	# correr se desactiva al soltar shift
	if Input.is_action_just_released("run_dash"):
		is_running = false

	# dash instantáneo (solo al presionar)
	if Input.is_action_just_pressed("run_dash") and dash_cooldown <= 0.0:
		is_dashing = true
		dash_timer = DASH_TIME
		dash_direction = direction
		if dash_direction == Vector3.ZERO:
			dash_direction = -global_transform.basis.z.normalized()
		dash_direction = dash_direction.normalized()

	#  DASH EXECUTION
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED
		velocity.y = 0.0
		if dash_timer <= 0.0:
			is_dashing = false
			dash_cooldown = DASH_COOLDOWN

	#  GRAVEDAD + SALTO
	if not is_on_floor():
		if velocity.y > 0.0:
			velocity.y -= GRAVITY_JUMP * delta
		else:
			velocity.y -= GRAVITY_FALL * delta
	if Input.is_action_just_released("saltar") and velocity.y > 0.0:
		velocity.y *= JUMP_CUT_MULT
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# MOVIMIENTO NORMAL, CORRIENDO O ACECHANDO
	if not is_dashing:
		var current_speed := WALK_SPEED
		if is_running:
			current_speed = RUN_SPEED
		elif is_crouching:
			current_speed = CROUCH_SPEED
		var target_vel = direction * current_speed
		velocity.x = lerp(velocity.x, target_vel.x, delta * 11.0)
		velocity.z = lerp(velocity.z, target_vel.z, delta * 11.0)

	move_and_slide()
