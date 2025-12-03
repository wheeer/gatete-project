extends CharacterBody3D

# ---------- NODOS ----------
@onready var hitbox: Area3D = $HitboxPata
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var pata_derecha: Node3D = $PataDerecha

# ---------- STATS ----------
@export var target_radius: float = 20.0

@export var stat_strength: int = 10
@export var stat_agility: int = 10
@export var stat_speed: int = 10
@export var stat_luck: int = 10
@export var stat_vitality: int = 10
@export var stat_composure: int = 10
@export var stat_resilience: int = 10

# ---------- DEFENSA / RECURSOS ----------
var hurt_cooldown: float = 0.0

var max_health: float
var health: float

var max_stamina: float
var stamina: float

var max_posture: float
var posture: float = 0.0

# ---------- VIDAS ----------
var max_lives: int = 9
var lives: int = max_lives

# ---------- LOOK-ON ----------
var current_target: Node3D = null
var is_locked_on := false
var last_direction: Vector3 = Vector3.FORWARD

# ---------- MOVIMIENTO ----------
const WALK_SPEED := 10.0
const RUN_SPEED := 15.0
const CROUCH_SPEED := 5.0     

const JUMP_VELOCITY := 7.0
const GRAVITY_JUMP := 14.0
const GRAVITY_FALL := 28.0
const JUMP_CUT_MULT := 0.4

# ---------- DASH ----------
const DASH_SPEED := 20.0
const DASH_TIME := 0.12
const DASH_COOLDOWN := 0.75
var dash_timer := 0.0
var dash_cooldown := 0.0
var is_dashing := false
var dash_direction: Vector3 = Vector3.ZERO

var is_running := false
var is_crouching := false

var attack_cooldown := 0.0
var is_attacking := false

# ---------- EMPUJE REAL ----------
var impulse: Vector3 = Vector3.ZERO
const IMPULSE_DECAY := 20.0


func _ready() -> void:
	lives = max_lives

	max_health = 50.0 + stat_vitality * 3.0
	health = max_health

	max_stamina = 50.0 + stat_speed * 3.0 + stat_agility * 2.0
	stamina = max_stamina

	max_posture = 50.0 + stat_composure * 5.0
	posture = 0.0


# =====================================================
#                   ATAQUE
# =====================================================
func atacar() -> void:
	if attack_cooldown > 0.0 or is_attacking:
		return

	is_attacking = true
	attack_cooldown = 0.25

	if is_locked_on and current_target:
		var tpos := current_target.global_transform.origin
		look_at(Vector3(tpos.x, global_transform.origin.y, tpos.z), Vector3.UP)
	else:
		look_at(global_transform.origin + last_direction, Vector3.UP)

	pata_derecha.visible = true

	if anim and anim.has_animation("ataque"):
		anim.play("ataque")

	hitbox.monitoring = true
	await get_tree().create_timer(0.12).timeout
	hitbox.monitoring = false
	pata_derecha.visible = false
	is_attacking = false


# =====================================================
#                  DAÑO AL GATO
# =====================================================
func receive_damage(amount: float, ignore_lives: bool = false, knockback_strength: float = 0.0) -> void:
	if hurt_cooldown > 0.0:
		return

	# empuje opcional extra desde el atacante (si lo usan)
	if knockback_strength != 0.0:
		apply_central_impulse(-global_transform.basis.z * knockback_strength)

	if ignore_lives:
		health -= amount
		hurt_cooldown = 0.4
		print("Daño REAL:", amount, "HP:", health)
	else:
		if lives > 0:
			lives -= 1
			var chip := amount * 0.25
			health -= chip
			hurt_cooldown = 0.3
			print("Daño leve:", chip, "HP:", health, "Vidas:", lives)
		else:
			health -= amount * 1.5
			hurt_cooldown = 0.45
			print("Daño REAL aumentado:", amount * 1.5, "HP:", health)

	if health <= 0.0:
		print("Gatito murió 💀")


# =====================================================
#             EMPUJE FÍSICO (desde dummie)
# =====================================================
func apply_central_impulse(vec: Vector3) -> void:
	impulse += vec


# =====================================================
#                PROCESO PRINCIPAL
# =====================================================
func _physics_process(delta: float) -> void:
	if hurt_cooldown > 0.0:
		hurt_cooldown -= delta

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	# ------------ INPUT ------------
	var input_2d := Vector2(
		Input.get_action_strength("derecha") - Input.get_action_strength("izquierda"),
		Input.get_action_strength("abajo") - Input.get_action_strength("arriba")
	).normalized()

	var direction := Vector3(input_2d.x, 0.0, input_2d.y)

	if direction != Vector3.ZERO:
		last_direction = direction.normalized()

	if direction != Vector3.ZERO and not is_dashing and not is_attacking and not is_locked_on:
		var target := global_transform.origin + direction
		look_at(Vector3(target.x, global_transform.origin.y, target.z), Vector3.UP)

	# ------------ AGACHAR / CORRER ------------
	is_crouching = Input.is_action_pressed("acechar")
	if is_crouching:
		is_running = false

	if Input.is_action_pressed("run_dash") and not is_crouching:
		is_running = true
	if Input.is_action_just_released("run_dash"):
		is_running = false

	# ------------ DASH ------------
	if Input.is_action_just_pressed("run_dash") and dash_cooldown <= 0.0:
		is_dashing = true
		dash_timer = DASH_TIME
		dash_direction = direction if direction != Vector3.ZERO else (-global_transform.basis.z).normalized()

	if dash_cooldown > 0.0:
		dash_cooldown -= delta

	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED
		velocity.y = 0.0

		if dash_timer <= 0.0:
			is_dashing = false
			dash_cooldown = DASH_COOLDOWN

	# ------------ GRAVEDAD / SALTO ------------
	if not is_on_floor():
		velocity.y -= (GRAVITY_JUMP if velocity.y > 0.0 else GRAVITY_FALL) * delta

	if Input.is_action_just_released("saltar") and velocity.y > 0.0:
		velocity.y *= JUMP_CUT_MULT

	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# ------------ MOVIMIENTO NORMAL ------------
	if not is_dashing:
		var current_speed := WALK_SPEED
		if is_running:
			current_speed = RUN_SPEED
		elif is_crouching:
			current_speed = CROUCH_SPEED

		var target_vel := direction * current_speed
		velocity.x = lerp(velocity.x, target_vel.x, delta * 11.0)
		velocity.z = lerp(velocity.z, target_vel.z, delta * 11.0)

	# ------------ LOCK-ON ------------
	if is_locked_on and current_target and not is_attacking and not is_dashing:
		var tpos := current_target.global_transform.origin
		look_at(Vector3(tpos.x, global_transform.origin.y, tpos.z), Vector3.UP)

		if global_transform.origin.distance_to(tpos) > target_radius:
			is_locked_on = false
			current_target = null

	# ------------ APLICAR IMPULSO ------------
	velocity.x += impulse.x
	velocity.z += impulse.z
	impulse = impulse.move_toward(Vector3.ZERO, IMPULSE_DECAY * delta)

	move_and_slide()


# =====================================================
#                  INPUT GLOBAL
# =====================================================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("atacar"):
		atacar()

	if event.is_action_pressed("look_on"):
		if is_locked_on:
			is_locked_on = false
			current_target = null
		else:
			current_target = get_closest_enemy()
			is_locked_on = current_target != null


# =====================================================
#          HITBOX PATITA → DAÑO A ENEMIGO
# =====================================================
func _on_hitbox_pata_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemigo") and body.has_method("take_damage"):
		body.take_damage(10.0)


# =====================================================
#             BUSCAR OBJETIVO CERCANO
# =====================================================
func get_closest_enemy() -> Node3D:
	var enemies := get_tree().get_nodes_in_group("enemigo")
	var closest: Node3D = null
	var closest_dist := target_radius

	for e in enemies:
		if not e is Node3D:
			continue

		var dist := global_transform.origin.distance_to(e.global_transform.origin)
		if dist < closest_dist:
			closest = e
			closest_dist = dist

	return closest
