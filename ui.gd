extends Control

@onready var life_bar: ProgressBar = $ShakeContainer/LifeBar
@onready var posture_bar: ProgressBar = $ShakeContainer/PostureBar
@onready var vidas_ui: HBoxContainer = $ShakeContainer/Vidas
@onready var shake_container: Control = $ShakeContainer

@export var full_heart: Texture2D
@export var empty_heart: Texture2D

var player: Node = null
var life_shake_timer := 0.0
const LIFE_SHAKE_DURATION := 0.15
const LIFE_SHAKE_STRENGTH := 6.0

var shake_base_position: Vector2

func _ready():
	player = get_tree().get_first_node_in_group("player")
	shake_base_position = shake_container.position
	_update_hearts()
	
func trigger_life_shake():
	life_shake_timer = LIFE_SHAKE_DURATION

func _process(_delta):
	if player == null:
		return

	# VIDA
	life_bar.max_value = player.max_health

	var prev_value := life_bar.value
	life_bar.value = player.health

	if life_bar.value < prev_value:
		trigger_life_shake()

	# COMPOSTURA
	posture_bar.max_value = player.max_posture
	posture_bar.value = player.posture
	# --------- SHAKE VIDA ---------
	if life_shake_timer > 0.0:
		life_shake_timer -= _delta
		var offset_x := randf_range(-LIFE_SHAKE_STRENGTH, LIFE_SHAKE_STRENGTH)
		shake_container.position.x = shake_base_position.x + offset_x
	else:
		shake_container.position = shake_base_position
	# VIDAS
	_update_hearts()

func _update_hearts():
	if player == null:
		return

	for i in range(vidas_ui.get_child_count()):
		var heart := vidas_ui.get_child(i)
		if i < player.lives:
			heart.texture = full_heart
		else:
			heart.texture = empty_heart
