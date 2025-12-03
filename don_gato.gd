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

# ---------- RECUPERACIÓN AÉREA / STUN ----------
var can_recover_in_air: bool = false
var attempted_recovery: bool = false
var recovery_window: float = 0.35
var recovery_timer: float = 0.0
var stunned: bool = false
var stun_timer: float = 0.0
var pending_recovery_is_strong: bool = false

# ---------- TIME STOP ----------
var timestop: bool = false
var timestop_timer: float = 0.0
const TIMESTOP_DURATION := 0.20   # 200ms, ajustable

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

func receive_damage(amount: float, ignore_lives: bool = false, knockback_strength: float = 0.0) -> void:
	if hurt_cooldown > 0.0:
		return

	# ============================================
	# DEBUG PRINT — ENTRADA DE DAÑO
	# ============================================
	print("=== DAÑO RECIBIDO ===")
	print("• Daño solicitado:", amount)
	print("• HP antes:", health)
	print("• Vidas:", lives)
	print("• Postura:", posture)

	# empuje opcional extra
	if knockback_strength != 0.0:
		apply_central_impulse(-global_transform.basis.z * knockback_strength)

	# ============================================
	# DAÑO REAL (IGNORA VIDAS)
	# ============================================
	if ignore_lives:
		health -= amount
		hurt_cooldown = 0.40
		print("→ DAÑO REAL aplicado:", amount)
		print("HP ahora:", health)
		print("---------------------")

		if health <= 0.0:
			print("💀 Gatito murió (daño real)")
		return

	# ============================================
	# DAÑO LEVE (AÚN QUEDAN VIDAS)
	# ============================================
	if lives > 0:
		lives -= 1
		var chip := amount * 0.25
		health -= chip
		hurt_cooldown = 0.30

		print("→ DAÑO LEVE (por sistema de 9 vidas)")
		print("    Daño reducido a:", chip)
		print("    Vidas restantes:", lives)
		print("HP ahora:", health)
		print("---------------------")

		if health <= 0.0:
			print("💀 Gatito murió (daño leve reducido)")
		return

	# ============================================
	# DAÑO AUMENTADO (SIN VIDAS)
	# ============================================
	var real_damage := amount * 1.5
	health -= real_damage
	hurt_cooldown = 0.45

	print("→ DAÑO REAL ++ aumentado (sin vidas)")
	print("    Daño aumentado:", real_damage)
	print("HP ahora:", health)
	print("---------------------")

	if health <= 0.0:
		print("💀 Gatito murió (fin de vidas)")


# =====================================================
#             EMPUJE FÍSICO (desde dummie)
# =====================================================
func apply_central_impulse(vec: Vector3) -> void:
	impulse += vec * 0.6
# =====================================================
#             habilitar recuperacion aerea 
# =====================================================
func enable_air_recovery(is_strong: bool = true) -> void:
	can_recover_in_air = true
	attempted_recovery = false
	pending_recovery_is_strong = is_strong
	recovery_timer = recovery_window

func perform_air_recovery() -> void:
	if not can_recover_in_air:
		return

	# ÉXITO: se hizo dentro de la ventana (aún queda tiempo)
	if recovery_timer > 0.1:
		print("Recuperación felina PERFECTA 😼")

		# corta la caída y da un pequeño ajuste
		velocity.y = 0.0
		apply_central_impulse(-global_transform.basis.z * 2.0)

		# recompensa: reducir un poco el daño/postura si fue empujón fuerte
		if pending_recovery_is_strong:
			health = min(health + 5.0, max_health)
			posture = max(posture - 15.0, 0.0)
	else:
		# FALLO: se presionó tarde
		print("Recuperación fallida → stun 0.5s")

		if pending_recovery_is_strong and lives > 0:
			lives -= 1
			print("Perdiste una vida por mala caída. Vidas:", lives)

		stunned = true
		stun_timer = 0.5

	can_recover_in_air = false
	attempted_recovery = true
	pending_recovery_is_strong = false

# =====================================================
#                ACTIVAR TIMESTOP
# =====================================================
func activate_timestop():
	timestop = true
	timestop_timer = TIMESTOP_DURATION
	print("⏸ TIME STOP ACTIVADO")

# =====================================================
#                PROCESO PRINCIPAL
# =====================================================
func _physics_process(delta: float) -> void:
	if hurt_cooldown > 0.0:
		hurt_cooldown -= delta

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	# --- si está stuneado, no puede moverse ni hacer nada ---
	if stunned:
		stun_timer -= delta
		velocity = Vector3.ZERO
		impulse = Vector3.ZERO

		if stun_timer <= 0.0:
			stunned = false
			print("Stun finalizado")

	# --- TIME STOP ---
	if timestop:
		timestop_timer -= delta
		velocity = velocity  # sigue volando
		# detener IA y animaciones (solo jugador)
		if anim:
			anim.speed_scale = 0.0

		if timestop_timer <= 0.0:
			timestop = false
			if anim:
				anim.speed_scale = 1.0
			print("▶ TIME STOP TERMINADO")
			
		move_and_slide()
		return

	# --- ventana de recuperación aérea ---
	if can_recover_in_air:
		recovery_timer -= delta

		# si se acabó el tiempo y no intentó recuperarse
		if recovery_timer <= 0.0 and not attempted_recovery:
			print("No te recuperaste → mala caída")

			if pending_recovery_is_strong and lives > 0:
				lives -= 1
				print("Perdiste una vida por no recuperarte. Vidas:", lives)

			stunned = true
			stun_timer = 0.5
			can_recover_in_air = false
			pending_recovery_is_strong = false

	# --- aplicar empuje ANTES del movimiento ---
	velocity.x += impulse.x
	velocity.z += impulse.z
	impulse = impulse.move_toward(Vector3.ZERO, IMPULSE_DECAY * delta)

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

	move_and_slide()

# =====================================================
#                  INPUT GLOBAL
# =====================================================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("atacar"):
		atacar()

	# intentar recuperación en el aire
	if event.is_action_pressed("saltar"):
		if can_recover_in_air and not attempted_recovery:
			perform_air_recovery()

	if event.is_action_pressed("look_on"):
		if is_locked_on:
			is_locked_on = false
			current_target = null
		else:
			current_target = get_closest_enemy()
			is_locked_on = current_target != null
			
	if event.is_action_pressed("recompostura"):
		if can_recover_in_air and not attempted_recovery:
			perform_air_recovery()


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
