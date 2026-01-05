extends CharacterBody3D

enum CatState {
	NORMAL,
	DASHING,
	STUNNED,
	TIMESTOP
}

var state: CatState = CatState.NORMAL

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
var combat_timer: float = 0.0
const COMBAT_GRACE_TIME := 3.0

# ---------- ATAQUES / COMBOS ----------
const COMBO_MAX := 3
const COMBO_RESET_TIME := 0.5

const LIGHT_ATTACK_DAMAGE := 10.0
const AIR_ATTACK_DAMAGE := 8.0
const CHARGED_ATTACK_DAMAGE := 25.0

var combo_index: int = 0
var combo_timer: float = 0.0

var is_charging: bool = false
var charge_timer: float = 0.0
const CHARGE_MIN_TIME := 0.5   # tiempo mínimo para considerarlo "cargado"

var current_attack_damage: float = LIGHT_ATTACK_DAMAGE

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

var stun_timer: float = 0.0
var pending_recovery_is_strong: bool = false

# ---------- TIME STOP ----------

var timestop_timer: float = 0.0
const TIMESTOP_DURATION := 0.35   # 200ms, ajustable
var timestop_saved_velocity: Vector3 = Vector3.ZERO
var timestop_saved_impulse: Vector3 = Vector3.ZERO
var timestop_has_saved_state: bool = false


func _ready() -> void:
	lives = max_lives
	max_health = 50.0 + stat_vitality * 3.0
	health = max_health
	max_stamina = 50.0 + stat_speed * 3.0 + stat_agility * 2.0
	stamina = max_stamina
	max_posture = 50.0 + stat_composure * 5.0
	posture = 0.0

# =====================================================
#              SISTEMA DE COMPOSTURA
# =====================================================

func add_posture(amount: float) -> void:
	if state == CatState.STUNNED:
		return

	posture += amount
	posture = clamp(posture, 0.0, max_posture)

	print("➕ Postura +", amount, "→", posture, "/", max_posture)

	if posture >= max_posture:
		break_posture()
func reduce_posture(amount: float) -> void:
	posture -= amount
	posture = clamp(posture, 0.0, max_posture)

	print("➖ Postura -", amount, "→", posture, "/", max_posture)
func break_posture() -> void:
	print("💥 POSTURA ROTA")

	posture = 0.0
	state = CatState.STUNNED
	stun_timer = 0.8   # ajustable

# =====================================================
#                   ATAQUE
# =====================================================
func atacar(attack_type: String = "auto") -> void:
	if attack_cooldown > 0.0 or is_attacking:
		return
	if state != CatState.NORMAL:
		return
	# decidir tipo de ataque si viene "auto"
	var final_type := attack_type

	if final_type == "auto":
		if not is_on_floor():
			final_type = "air"
		else:
			final_type = "light"

	is_attacking = true

	match final_type:
		"light":
			_do_light_attack()
		"air":
			_do_air_attack()
		"charged":
			_do_charged_attack()

func _do_light_attack() -> void:
	# manejar combo
	if combo_timer > 0.0:
		combo_index = (combo_index % COMBO_MAX) + 1
	else:
		combo_index = 1

	combo_timer = COMBO_RESET_TIME

	# dañar un poco más en golpes avanzados del combo
	current_attack_damage = LIGHT_ATTACK_DAMAGE * (1.0 + 0.3 * float(combo_index - 1))

	attack_cooldown = 0.22

	# orientación
	if is_locked_on and current_target:
		var tpos := current_target.global_transform.origin
		look_at(Vector3(tpos.x, global_transform.origin.y, tpos.z), Vector3.UP)
	else:
		look_at(global_transform.origin + last_direction, Vector3.UP)

	pata_derecha.visible = true

	# seleccionar anim según combo (ajusta nombres a lo que tengas)
	var _anim_name := "ataque"
	if anim:
		var combo_anim := "ataque_" + str(combo_index)
		if anim.has_animation(combo_anim):
			anim.play(combo_anim)
		else:
			anim.play("ataque")

	hitbox.monitoring = true
	await get_tree().create_timer(0.12).timeout
	hitbox.monitoring = false
	pata_derecha.visible = false
	is_attacking = false


func _do_air_attack() -> void:
	combo_index = 0
	combo_timer = 0.0
	current_attack_damage = AIR_ATTACK_DAMAGE
	attack_cooldown = 0.25

	# pequeño impulso hacia adelante opcional
	var forward := -global_transform.basis.z
	velocity.x += forward.x * 3.0
	velocity.z += forward.z * 3.0

	pata_derecha.visible = true

	if anim:
		if anim.has_animation("ataque_aereo"):
			anim.play("ataque_aereo")
		else:
			anim.play("ataque")

	hitbox.monitoring = true
	await get_tree().create_timer(0.10).timeout
	hitbox.monitoring = false
	pata_derecha.visible = false
	is_attacking = false


func _do_charged_attack() -> void:
	combo_index = 0
	combo_timer = 0.0
	current_attack_damage = CHARGED_ATTACK_DAMAGE
	attack_cooldown = 0.45

	# mirar al objetivo si lo hay
	if is_locked_on and current_target:
		var tpos := current_target.global_transform.origin
		look_at(Vector3(tpos.x, global_transform.origin.y, tpos.z), Vector3.UP)
	else:
		look_at(global_transform.origin + last_direction, Vector3.UP)

	pata_derecha.visible = true

	if anim:
		if anim.has_animation("ataque_cargado"):
			anim.play("ataque_cargado")
		else:
			anim.play("ataque")

	hitbox.monitoring = true
	await get_tree().create_timer(0.18).timeout
	hitbox.monitoring = false
	pata_derecha.visible = false
	is_attacking = false


func receive_damage(amount: float, ignore_lives: bool = false, knockback_strength: float = 0.0) -> void:
	if hurt_cooldown > 0.0:
		return
	
	combat_timer = COMBAT_GRACE_TIME

	# --- COMPOSTURA POR DAÑO ---
	var posture_gain := amount * 0.8

	if knockback_strength > 0.0:
		posture_gain += knockback_strength * 0.5

	add_posture(posture_gain)

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
			reduce_posture(20.0)
	else:
		# FALLO: se presionó tarde
		print("Recuperación fallida → stun 0.5s")

		if pending_recovery_is_strong and lives > 0:
			lives -= 1
			print("Perdiste una vida por mala caída. Vidas:", lives)

		state = CatState.STUNNED
		stun_timer = 0.5
		add_posture(25.0)
		
	can_recover_in_air = false
	attempted_recovery = true
	pending_recovery_is_strong = false

# =====================================================
#                ACTIVAR TIMESTOP
# =====================================================
func activate_timestop():
	state = CatState.TIMESTOP
	timestop_timer = TIMESTOP_DURATION
	timestop_has_saved_state = false
	print("⏸ TIME STOP ACTIVADO")
# =====================================================	
#                funcion estado pela
# =====================================================
func is_in_combat() -> bool:
	return combat_timer > 0.0 or is_locked_on
# =====================================================
#                PROCESO PRINCIPAL
# =====================================================
func _physics_process(delta: float) -> void:
	# --- COMBAT TIMER ---#
	if combat_timer > 0.0:
		combat_timer -= delta
	# --- COOLDOWNS ---
	if hurt_cooldown > 0.0:
		hurt_cooldown -= delta

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	# --- CARGA DE ATAQUE ---
	if is_charging:
		charge_timer += delta

	# --- TIMER DEL COMBO ---
	if combo_timer > 0.0 and not is_attacking:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_index = 0

	# --- STUN ---
	if state == CatState.STUNNED:
		stun_timer -= delta
		velocity = Vector3.ZERO
		impulse = Vector3.ZERO

		if stun_timer <= 0.0:
			state = CatState.NORMAL
			print("Stun finalizado")

		move_and_slide()
		return
	# --- TIME STOP ---
	if state == CatState.TIMESTOP:
		timestop_timer -= delta

		# Guardar estado SOLO UNA VEZ, al inicio del timestop
		if not timestop_has_saved_state:
			timestop_saved_velocity = velocity
			timestop_saved_impulse = impulse
			timestop_has_saved_state = true

		# Congelar movimiento
		velocity = Vector3.ZERO
		impulse = Vector3.ZERO

		# Congelar animación
		if anim:
			anim.speed_scale = 0.0

		# Mantener física congelada
		move_and_slide()

		# Terminar timestop
		if timestop_timer <= 0.0:
			state = CatState.NORMAL

			# Restaurar empuje del golpe fuerte
			velocity = timestop_saved_velocity
			impulse = timestop_saved_impulse
			timestop_has_saved_state = false

			if anim:
				anim.speed_scale = 1.0

			print("▶ TIME STOP TERMINADO")

		return
	# --- RECUPERACIÓN DE POSTURA ---
	if state == CatState.NORMAL and posture > 0.0:
		if is_in_combat():
			# en pelea: baja lento
			posture -= 6.0 * delta
		else:
			# fuera de pelea: baja rápido
			posture -= 18.0 * delta

		posture = max(posture, 0.0)

	# --- ventana de recuperación aérea ---
	if can_recover_in_air:
		recovery_timer -= delta

		if recovery_timer <= 0.0 and not attempted_recovery:
			print("No te recuperaste → mala caída")

			if pending_recovery_is_strong and lives > 0:
				lives -= 1
				print("Perdiste una vida por no recuperarte. Vidas:", lives)

			state = CatState.STUNNED
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

	if direction != Vector3.ZERO and state != CatState.DASHING and not is_attacking and not is_locked_on:
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
	if Input.is_action_just_pressed("run_dash") and dash_cooldown <= 0.0 and state == CatState.NORMAL:
		state = CatState.DASHING
		dash_timer = DASH_TIME
		dash_direction = direction if direction != Vector3.ZERO else (-global_transform.basis.z).normalized()

	if dash_cooldown > 0.0:
		dash_cooldown -= delta

	if state == CatState.DASHING:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED
		velocity.y = 0.0

		if dash_timer <= 0.0:
			state = CatState.NORMAL
			dash_cooldown = DASH_COOLDOWN


	# ------------ GRAVEDAD / SALTO ------------
	if not is_on_floor():
		velocity.y -= (GRAVITY_JUMP if velocity.y > 0.0 else GRAVITY_FALL) * delta

	if Input.is_action_just_released("saltar") and velocity.y > 0.0:
		velocity.y *= JUMP_CUT_MULT

	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# ------------ MOVIMIENTO NORMAL ------------
	if state != CatState.DASHING:
		var current_speed := WALK_SPEED
		if is_running:
			current_speed = RUN_SPEED
		elif is_crouching:
			current_speed = CROUCH_SPEED

		var target_vel := direction * current_speed
		velocity.x = lerp(velocity.x, target_vel.x, delta * 11.0)
		velocity.z = lerp(velocity.z, target_vel.z, delta * 11.0)

	# ------------ LOCK-ON ------------
	if is_locked_on:

		# 1. Si el target murió o fue eliminado
		if not is_instance_valid(current_target):

			var old := current_target
			current_target = get_closest_enemy()

			# apagar marcador del viejo SOLO si sigue vivo
			if is_instance_valid(old):
				_set_target_marker(old, false)

			# si no queda nadie → salir del lock-on
			if current_target == null:
				is_locked_on = false
				return

			# nuevo marcador
			_set_target_marker(current_target, true)

		else:
			# 2. Si el target existe, mirar hacia él
			if not is_attacking and state != CatState.DASHING:
				var tpos := current_target.global_transform.origin
				look_at(Vector3(tpos.x, global_transform.origin.y, tpos.z), Vector3.UP)

			# 3. Si está fuera del rango, buscar otro
			if global_transform.origin.distance_to(current_target.global_transform.origin) > target_radius:

				var old_target := current_target
				current_target = get_closest_enemy()

				# apagar marcador del objetivo anterior SOLO si sigue vivo
				if is_instance_valid(old_target):
					_set_target_marker(old_target, false)

				# no hay nuevo enemigo → salir del lock-on
				if current_target == null:
					is_locked_on = false
					return

				# nueva marca
				_set_target_marker(current_target, true)

	move_and_slide()

# =====================================================
#                  INPUT GLOBAL
# =====================================================
func _input(event: InputEvent) -> void:
		# --- ATAQUE / CARGA ---
	if event.is_action_pressed("atacar"):
		is_charging = true
		charge_timer = 0.0

	if event.is_action_released("atacar"):
		if not is_charging:
			return

		is_charging = false

		# cargado (solo en suelo)
		if charge_timer >= CHARGE_MIN_TIME and is_on_floor():
			atacar("charged")
		else:
			atacar("auto")

	# intentar recuperación en el aire
	if event.is_action_pressed("saltar"):
		if can_recover_in_air and not attempted_recovery:
			perform_air_recovery()

	if event.is_action_pressed("look_on"):

		# APAGAR si ya había lock-on
		if is_locked_on:
			if is_instance_valid(current_target):
				_set_target_marker(current_target, false)

			is_locked_on = false
			current_target = null
			return

		# ACTIVAR NUEVO LOCK-ON
		var new_target := get_closest_enemy()
		if new_target:
			current_target = new_target
			is_locked_on = true
			_set_target_marker(current_target, true)

	if event.is_action_pressed("recompostura"):
		if can_recover_in_air and not attempted_recovery:
			perform_air_recovery()
	
	# cambiar objetivo con scroll
	if is_locked_on and event is InputEventMouseButton:

		# Scroll arriba
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cycle_target(+1)

		# Scroll abajo
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cycle_target(-1)

# =====================================================
#          HITBOX PATITA → DAÑO A ENEMIGO
# =====================================================
func _on_hitbox_pata_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemigo") and body.has_method("take_damage"):
		body.take_damage(current_attack_damage)

# =====================================================
#             SET TARGET MARKER
# =====================================================
func _set_target_marker(enemy: Node3D, active: bool) -> void:
	if enemy == null:
		return
	if not is_instance_valid(enemy):
		return
	if not enemy.has_node("LockOnMarker"):
		return

	enemy.get_node("LockOnMarker").visible = active
# =====================================================
# LISTA QUE DEVUELVE TODOS LOS ENEMIGOS ORDENADOS POR DISTANCIA
# =====================================================
func get_enemies_sorted() -> Array:
	var enemies := get_tree().get_nodes_in_group("enemigo")
	var valid := []

	for e in enemies:
		if not is_instance_valid(e):
			continue
		if not e is Node3D:
			continue

		var dist := global_transform.origin.distance_to(e.global_transform.origin)
		if dist <= target_radius:
			valid.append({"ref": e, "dist": dist})

	# ordenar por distancia
	valid.sort_custom(func(a, b): return a["dist"] < b["dist"])

	# devolver solo la referencia al nodo
	return valid.map(func(d): return d["ref"])

# =====================================================
#         CAMBIO DE OBJETIVO
# =====================================================	
func cycle_target(direction: int) -> void:
	# direction = +1 scroll arriba, -1 scroll abajo

	var list := get_enemies_sorted()
	if list.is_empty():
		return

	# si no hay target actual, fijar el primero
	if current_target == null or not is_instance_valid(current_target):
		current_target = list[0]
		_set_target_marker(current_target, true)
		is_locked_on = true
		return

	# buscar índice del enemigo actual
	var index := list.find(current_target)
	if index == -1:
		# si el actual no está, fijar el primero
		current_target = list[0]
		_set_target_marker(current_target, true)
		return

	# nuevo índice
	var new_index := (index + direction) % list.size()
	if new_index < 0:
		new_index = list.size() - 1

	var old := current_target
	current_target = list[new_index]

	# apagar marcador del viejo
	if is_instance_valid(old):
		_set_target_marker(old, false)

	# activar marcador del nuevo
	_set_target_marker(current_target, true)

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
