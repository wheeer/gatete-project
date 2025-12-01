extends CharacterBody3D

@onready var hitbox: Area3D = $HitboxPata
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var pata_derecha := $PataDerecha
var _last_direction: Vector3 = Vector3.FORWARD

# MOVIMIENTO
const WALK_SPEED := 10.0
const RUN_SPEED := 15.0
const CROUCH_SPEED := 5.0     

# SALTO
const JUMP_VELOCITY := 7.0
const GRAVITY_JUMP := 14.0
const GRAVITY_FALL := 28.0
const JUMP_CUT_MULT := 0.4

# DASH
const DASH_SPEED := 20.0
const DASH_TIME := 0.12
const DASH_COOLDOWN := 0.75
var dash_timer := 0.12
var dash_cooldown := 0.75
var is_dashing := false
var dash_direction := Vector3.ZERO

# CORRER / ACECHAR
var is_running := false
var is_crouching := false

# ATAQUE
var attack_cooldown := 0.0
var is_attacking := false

func atacar():
	if attack_cooldown > 0.0 or is_attacking:
		return

	is_attacking = true
	attack_cooldown = 0.25

	# mirar hacia la dirección guardada
	look_at(global_transform.origin + _last_direction, Vector3.UP)

	# Mostrar la pata
	pata_derecha.visible = true

	# reproducir animación
	if anim and anim.has_animation("ataque"):
		anim.play("ataque")

	# activar el hitbox
	hitbox.monitoring = true
	await get_tree().create_timer(0.12).timeout

	# ocultar la pata
	pata_derecha.visible = false

	# apagar hitbox
	hitbox.monitoring = false
	is_attacking = false


func _physics_process(delta: float) -> void:

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	var input_2d = Vector2(
		Input.get_action_strength("derecha") - Input.get_action_strength("izquierda"),
		Input.get_action_strength("abajo") - Input.get_action_strength("arriba")
	).normalized()

	var direction = Vector3(input_2d.x, 0, input_2d.y)
	# guarda dirección usada para atacar
	if direction != Vector3.ZERO:
		_last_direction = direction.normalized()
		
	# rotar cuerpo hacia la dirección de movimiento
	if direction != Vector3.ZERO and not is_dashing and not is_attacking:
		var target = global_transform.origin + direction
		look_at(target, Vector3.UP)
	

	# acechar
	is_crouching = Input.is_action_pressed("acechar")
	if is_crouching:
		is_running = false

	# correr
	if Input.is_action_pressed("run_dash") and not is_crouching:
		is_running = true
	if Input.is_action_just_released("run_dash"):
		is_running = false

	# dash
	if Input.is_action_just_pressed("run_dash") and dash_cooldown <= 0.0:
		is_dashing = true
		dash_timer = DASH_TIME
		dash_direction = direction

		if dash_direction == Vector3.ZERO:
			var f = -global_transform.basis.z
			if f.length() < 0.001:
				f = Vector3.FORWARD
			dash_direction = f.normalized()
	else:
		dash_direction = dash_direction.normalized()

	if dash_cooldown > 0.0:
		dash_cooldown -= delta

	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED
		velocity.y = 0.0
		if dash_timer <= 0.0:
			is_dashing = false
			dash_cooldown = DASH_COOLDOWN

	# salto y gravedad
	if not is_on_floor():
		if velocity.y > 0.0:
			velocity.y -= GRAVITY_JUMP * delta
		else:
			velocity.y -= GRAVITY_FALL * delta

	if Input.is_action_just_released("saltar") and velocity.y > 0.0:
		velocity.y *= JUMP_CUT_MULT

	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# movimiento normal
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


func _input(event):
	if event.is_action_pressed("atacar"):
		atacar()


func _on_hitbox_pata_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemigo") and body.has_method("recibir_daño"):
		body.take_damage(10)
