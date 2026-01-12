extends CharacterBody3D

@onready var marker := $LockOnMarker

@export var player: CharacterBody3D
@export var move_speed: float = 4.0
@export var stop_distance: float = 2.0
@export var gravity: float = 30.0

@export var max_health: int = 30
@export var contact_damage: float = 6.0
@export var strong_damage: float = 10.0

@export var push_threshold: int = 5   # 1 de cada 5 empujes es fuerte

var health: int
var contact_cooldown: float = 0.0

func _ready() -> void:
	randomize()
	health = max_health
	

func _physics_process(delta: float) -> void:
	if not player:
		return

	if contact_cooldown > 0.0:
		contact_cooldown -= delta

	# seguir al jugador
	var to_player := player.global_transform.origin - global_transform.origin
	var flat := Vector3(to_player.x, 0.0, to_player.z)
	var dist := flat.length()

	if dist > stop_distance:
		var dir := flat.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	# gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

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

	# probabilidad de empujón fuerte
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
	health -= int(amount)
	print("Dummie recibe", amount, "vida:", health)

	if health <= 0:
		print("Dummie murió")

		# --- RECUPERAR CORAZÓN AL MATAR ---
		if player and player.is_inside_tree():
			if player.lives < player.max_lives:
				player.lives += 1
				print("Corazón recuperado. Vidas:", player.lives)

		queue_free()
