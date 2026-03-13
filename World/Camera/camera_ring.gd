extends CharacterBody3D

@export var target: Node3D
@export var smooth: float = 6.0
@export var offset: Vector3 = Vector3(0, 7, 7)
# ---- Inclinación automática ----
@export var tilt_min: float = -30.0   # cuando el gato está justo debajo
@export var tilt_max: float = -5.0    # cuando está lejos
@export var tilt_distance: float = 6.0  # sensibilidad
@onready var cam: Camera3D = $Camera3D  # tu cámara real

func _physics_process(delta: float) -> void:
	if not target:
		return

	var tgt: Vector3 = target.global_transform.origin
	var desired_pos: Vector3 = tgt + offset

	# ---- movimiento con colisión real ----
	velocity = (desired_pos - global_transform.origin) * smooth
	move_and_slide()

	### ---------- INCLINACIÓN EN X ----------- ###
	var dist: float = abs(global_transform.origin.z - tgt.z)
	var t: float = clamp(dist / tilt_distance, 0.0, 1.0)
	var tilt_x: float = lerp(tilt_min, tilt_max, t)

	cam.rotation_degrees.x = lerp(cam.rotation_degrees.x, tilt_x, delta * 4.0)
