extends CharacterBody3D
enum EnemyPosture {
	DEFENSIVO_ACTIVO,
	AGRESIVO_OPORTUNISTA,
	ASUSTADO,
	# placeholders (NO usar aún)
	ULTIMO_AIRE,
	FINGIR_MUERTE
}

enum EnemyDecision {
	NONE,
	ESCAPAR,
	PELEAR_DESESPERADO,
	FINGIR_MUERTE
}

var decision: EnemyDecision = EnemyDecision.NONE

@onready var marker := $LockOnMarker
@onready var debug_label: Label3D = $"DebugLabel"

@export var player: CharacterBody3D
@export var move_speed: float = 4.0
@export var stop_distance: float = 2.0
@export var gravity: float = 30.0

@export var max_health: int = 30
@export var contact_damage: float = 6.0
@export var strong_damage: float = 10.0

@export var push_threshold: int = 5   # 1 de cada 5 empujes es fuerte
@export var feign_wake_distance: float = 2.2
@export var feign_max_time: float = 2.5

@export var psychology: EnemyPsychology

var current_temple: float = 0.0
var temple_recovery_rate: float = 5.0 # por segundo

var feign_timer: float = 0.0

var posture: EnemyPosture = EnemyPosture.DEFENSIVO_ACTIVO
var feign_death_active: bool = false

var health: int
var contact_cooldown: float = 0.0
var lock_on_priority: float = 1.0

var hits_taken: int = 0

func _ready() -> void:
	randomize()
	health = max_health

	# crear psychology si no existe
	if psychology == null:
		psychology = EnemyPsychology.new()
		randomize_psychology()

	# configurar desde personalidad
	psychology.configure_from_personality()
	current_temple = psychology.base_temple
	print("🧠 temple inicial:", current_temple)
	print("🧠 personalidad:", psychology.personality)
	print("🧠 temple base:", psychology.base_temple)

	print("Postura inicial del ratón:", posture)

func randomize_psychology() -> void:
	var personalities = [
		EnemyPsychology.Personality.MIEDOSO,
		EnemyPsychology.Personality.VALEROSO,
		EnemyPsychology.Personality.ASTUTO
	]

	psychology.personality = personalities.pick_random()


func enter_feign_death() -> void:
	if feign_death_active:
		return

	feign_death_active = true
	decision = EnemyDecision.FINGIR_MUERTE
	velocity = Vector3.ZERO
	feign_timer = feign_max_time

	lock_on_priority = 0.2
	print("Ratón finge muerte")


func _physics_process(delta: float) -> void:
	
	if not player:
		return
	
	if decision == EnemyDecision.NONE:
		current_temple += temple_recovery_rate * delta
		current_temple = min(current_temple, psychology.base_temple)
		evaluate_temple_decision()
		update_posture_from_temple()

	if contact_cooldown > 0.0:
		contact_cooldown -= delta
		
	if decision == EnemyDecision.FINGIR_MUERTE:
		process_feign_death(delta)
		move_and_slide()
		return


	if decision == EnemyDecision.ESCAPAR:
		flee_from_player(delta)
		move_and_slide()
		return

	# seguir al jugador
	var to_player := player.global_transform.origin - global_transform.origin
	var flat := Vector3(to_player.x, 0.0, to_player.z)
	var dist := flat.length()

	var desired_speed := move_speed
	var desired_stop := stop_distance

	if decision == EnemyDecision.PELEAR_DESESPERADO:
		desired_speed *= 1.6
		desired_stop = 0.8   # se te pega más

	if dist > desired_stop:
		var dir := flat.normalized()
		velocity.x = dir.x * desired_speed
		velocity.z = dir.z * desired_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, desired_speed)
		velocity.z = move_toward(velocity.z, 0.0, desired_speed)

	# gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if Engine.get_physics_frames() % 120 == 0:
		print(
			"🧠 Temple:", snapped(current_temple, 0.1),
			"| Panic <", psychology.panic_threshold,
			"| Desperation >", psychology.desperation_threshold,
			"| Decisión:", decision
			)

	move_and_slide()
	if debug_label:
		debug_label.text = (
			"Postura: " + EnemyPosture.keys()[posture] + "\n" +
			"Decisión: " + EnemyDecision.keys()[decision] + "\n" +
			"Temple: " + str(snapped(current_temple, 0.1))
		)


func evaluate_temple_decision() -> void:
	if decision != EnemyDecision.NONE:
		return

	if current_temple <= psychology.panic_threshold:
		decision = EnemyDecision.ESCAPAR
		print("🧠 Temple crítico → PÁNICO")
		return

	if current_temple >= psychology.desperation_threshold:
		decision = EnemyDecision.PELEAR_DESESPERADO
		print("🧠 Temple alto → DESESPERACIÓN")
		return

func update_posture_from_temple() -> void:
	if current_temple <= psychology.panic_threshold:
		if posture != EnemyPosture.ASUSTADO:
			posture = EnemyPosture.ASUSTADO
			print("🧠 Postura → ASUSTADO")
		return

	if current_temple >= psychology.desperation_threshold:
		if posture != EnemyPosture.AGRESIVO_OPORTUNISTA:
			posture = EnemyPosture.AGRESIVO_OPORTUNISTA
			print("🧠 Postura → AGRESIVO")
		return

	if posture != EnemyPosture.DEFENSIVO_ACTIVO:
		posture = EnemyPosture.DEFENSIVO_ACTIVO
		print("🧠 Postura → DEFENSIVO")


func process_feign_death(delta: float) -> void:
	if not player:
		return

	feign_timer -= delta

	var dist := global_transform.origin.distance_to(player.global_transform.origin)

	# 1 jugador se acerca → reacción inmediata
	if dist <= feign_wake_distance:
		trigger_feign_reaction()
		return

	# 2 se acabó el tiempo → decide solo
	if feign_timer <= 0.0:
		trigger_feign_reaction()
func trigger_feign_reaction() -> void:
	feign_death_active = false
	lock_on_priority = 1.0

	var roll := randf()

	# ataque sucio + huida
	if roll < 0.6:
		print("Ratón despierta y ataca!")
		decision = EnemyDecision.PELEAR_DESESPERADO
		return

	# escape puro
	print("Ratón despierta y arranca!")
	decision = EnemyDecision.ESCAPAR

func flee_from_player(_delta: float) -> void:
	if not player:
		return

	var away := global_transform.origin - player.global_transform.origin
	away.y = 0.0

	if away.length() == 0:
		return

	var dir := away.normalized()
	velocity.x = dir.x * move_speed * 1.5
	velocity.z = dir.z * move_speed * 1.5

	if away.length() > 15.0:
		print("Ratón escapó del combate")
		queue_free()

# --- contacto físico con el gato (HitArea → body_entered) ---
func _on_hit_area_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	if contact_cooldown > 0.0:
		return

	contact_cooldown = 0.3

	var to_player := body.global_transform.origin - global_transform.origin
	var push_dir := Vector3(to_player.x, 0.0, to_player.z).normalized()

	var force := 6.0
	var is_strong := false

	# empuje base más agresivo si está desesperado
	if decision == EnemyDecision.PELEAR_DESESPERADO:
		force = 10.0

	# empujón fuerte SIEMPRE manda
	if randi() % push_threshold == 0:
		force = 16.0
		is_strong = true

	# --- EMPUJE FÍSICO ---
	if body.has_method("apply_central_impulse"):
		body.apply_central_impulse(push_dir * force)

	# --- EMPUJÓN FUERTE ---
	if is_strong:
		print("EMPÚJON FUERTE!")

		# habilitar recuperación aérea
		if body.has_method("enable_air_recovery"):
			body.enable_air_recovery(true)

		# activar time stop SOLO en fuerte
		if body.has_method("activate_timestop"):
			body.activate_timestop()

	# --- DAÑO AL GATO ---
	if body.has_method("receive_damage"):
		var dmg := 6.0
		if is_strong:
			dmg = 10.0

		print("Daño de empujón:", dmg)
		body.receive_damage(dmg, false, 0.0)

# --- recibir daño del gato ---
func take_damage(amount: float) -> void:
	# solo ignorar daño si está fingiendo muerte ACTIVAMENTE
	if decision == EnemyDecision.FINGIR_MUERTE and feign_death_active:
		return
		
	health -= int(amount)
	hits_taken += 1
	current_temple -= amount * 2.0
	print("🧠 temple baja a:", current_temple)
	print("Dummie recibe", amount, "vida:", health)

	# romper nervios por daño acumulado
	if hits_taken == 2 and decision == EnemyDecision.NONE:
		match psychology.personality:
			EnemyPsychology.Personality.MIEDOSO:
				decision = EnemyDecision.ESCAPAR
				print("Ratón entra en pánico!")

			EnemyPsychology.Personality.ASTUTO:
				enter_feign_death()
				print("Ratón intenta engañar!")

			EnemyPsychology.Personality.VALEROSO:
				decision = EnemyDecision.PELEAR_DESESPERADO
				print("Ratón se pone violento!")

	if health <= 0:
		print("Dummie murió")

		# --- RECUPERAR CORAZÓN AL MATAR ---
		if player and player.is_inside_tree():
			if player.lives < player.max_lives:
				player.lives += 1
				print("Corazón recuperado. Vidas:", player.lives)
	
		queue_free()
