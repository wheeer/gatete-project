extends Node2D

@onready var stamina_bar: ProgressBar = $StaminaBar

var target: Node3D = null
var stamina_comp: DonGatoStats = null

func initialize(_target: Node3D, _stamina: DonGatoStats) -> void:
	target = _target
	stamina_comp = _stamina
	stamina_bar.max_value = stamina_comp.stamina_max
	stamina_bar.value = stamina_comp.stamina
	stamina_comp.stamina_changed.connect(_on_stamina_changed)

func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	# Offset hacia abajo del jugador para que quede a sus pies
	var screen_pos := camera.unproject_position(target.global_position + Vector3(0, -0.8, 0))
	global_position = screen_pos

func _on_stamina_changed(current: float, max_val: float) -> void:
	stamina_bar.max_value = max_val
	stamina_bar.value = current
