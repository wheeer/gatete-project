extends Node2D

@onready var vida_bar: ProgressBar = $VBoxContainer/VidaBar
@onready var posture_bar: ProgressBar = $VBoxContainer/PostureBar
@onready var vida_label: Label = $VBoxContainer/VidaBar/VidaLabel
@onready var posture_label: Label = $VBoxContainer/PostureBar/PostureLabel

var health_component: HealthComponent
var posture_component: PostureComponent
var target: Node3D

func initialize(_target: Node3D, _health: HealthComponent, _posture: PostureComponent) -> void:
	target = _target
	health_component = _health
	posture_component = _posture
	health_component.health_changed.connect(_on_health_changed)
	posture_component.posture_changed.connect(_on_posture_changed)
	## Inicializar valores inmediatamente
	_on_health_changed(health_component.current_health, health_component.max_health)
	_on_posture_changed(posture_component.current_posture, posture_component.max_posture)

func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var screen_pos := camera.unproject_position(target.global_position + Vector3(0.5, 1.5, 0))
	global_position = screen_pos

func _on_health_changed(current: float, max_value: float) -> void:
	vida_bar.max_value = max_value
	vida_bar.value = current
	vida_label.text = "%d / %d" % [int(current), int(max_value)]

func _on_posture_changed(current: float, max_value: float) -> void:
	posture_bar.max_value = max_value
	posture_bar.value = current
	posture_label.text = "%d / %d" % [int(current), int(max_value)]
