extends Camera3D

@export var target: Node3D

@export var smooth: float = 3.0

@export var base_distance: float = 5.0
@export var base_tilt: float = -45.0

@export var tilt_range: float = 8.0
@export var zoom_range: float = 1.5


func _process(delta: float) -> void:
	if not target:
		return
	
	var cam_pos: Vector3 = global_transform.origin
	var tgt_pos: Vector3 = target.global_transform.origin

	# Distancia horizontal entre cámara y gato
	var distance_x: float = abs(cam_pos.x - tgt_pos.x)

	# ---- ROTACIÓN (tilt dinámico) ----
	var tilt: float = base_tilt - lerp(0.0, tilt_range, distance_x / 10.0)
	rotation_degrees.x = lerp(rotation_degrees.x, tilt, delta * smooth)

	# ---- DISTANCIA Z dinámica ----
	var target_distance: float = base_distance - lerp(0.0, zoom_range, distance_x / 10.0)
	var desired_z: float = tgt_pos.z + target_distance
	cam_pos.z = lerp(cam_pos.z, desired_z, delta * smooth)

	# ---- SEGUIMIENTO EN X ----
	cam_pos.x = lerp(cam_pos.x, tgt_pos.x, delta * smooth)

	position = cam_pos
