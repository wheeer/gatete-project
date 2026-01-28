extends Control

@onready var life_bar: ProgressBar = $ShakeContainer/LifeBar
@onready var posture_bar: ProgressBar = $ShakeContainer/PostureBar
@onready var vidas_ui: HBoxContainer = $ShakeContainer/Vidas
@onready var shake_container: Control = $ShakeContainer

@export var full_heart: Texture2D
@export var empty_heart: Texture2D

var last_lives: int = -1
var last_health: float = -1.0
var player: Node = null
var life_shake_timer := 0.0
var shake_base_position: Vector2
var life_flash_timer := 0.0
var last_posture: float = -1.0
var posture_flash_timer := 0.0
const POSTURE_FLASH_DURATION := 0.12
const POSTURE_BREAK_COLOR := Color(0.7, 0.3, 1.0) # violeta
const LIFE_FLASH_DURATION := 0.08
const LIFE_FLASH_COLOR := Color(1.0, 0.1, 0.1)
const LIFE_SHAKE_DURATION := 0.15
const LIFE_SHAKE_STRENGTH := 6.0
const LIFE_SAFE_COLOR := Color(0.2, 0.9, 0.3)    # verde
const LIFE_WARN_COLOR := Color(1.0, 0.7, 0.2)    # amarillo
const LIFE_DANGER_COLOR := Color(1.0, 0.25, 0.25) # rojo

func _ready():
	player = get_tree().get_first_node_in_group("player")
	shake_base_position = shake_container.position
	_update_hearts()

func _update_life_color():
	var ratio: float = player.health / player.max_health

	if ratio > 0.6:
		life_bar.modulate = LIFE_SAFE_COLOR
	elif ratio > 0.3:
		life_bar.modulate = LIFE_WARN_COLOR
	else:
		life_bar.modulate = LIFE_DANGER_COLOR

func trigger_posture_break():
	posture_flash_timer = POSTURE_FLASH_DURATION

func trigger_life_flash():
	life_flash_timer = LIFE_FLASH_DURATION

func trigger_life_shake():
	life_shake_timer = LIFE_SHAKE_DURATION

func _process(_delta):
	if player == null:
		return
	life_bar.value = player.health
	_update_life_color()

	# VIDA
	life_bar.max_value = player.max_health
	life_bar.value = player.health
	_update_life_color()
	
	if life_flash_timer > 0.0:
		life_flash_timer -= _delta
		life_bar.modulate = LIFE_FLASH_COLOR

	if last_health >= 0.0 and player.health < last_health:
		trigger_life_shake()
		trigger_life_flash()
	last_health = player.health

	# COMPOSTURA
	posture_bar.max_value = player.max_posture
	posture_bar.value = player.posture

	if posture_flash_timer > 0.0:
		posture_flash_timer -= _delta
		posture_bar.modulate = POSTURE_BREAK_COLOR
	else:
		posture_bar.modulate = Color.WHITE

	if last_posture > 0.0 and player.posture <= 0.0:
		trigger_posture_break()

	last_posture = player.posture

	# --------- SHAKE VIDA ---------
	if life_shake_timer > 0.0:
		life_shake_timer -= _delta
		var offset_x := randf_range(-LIFE_SHAKE_STRENGTH, LIFE_SHAKE_STRENGTH)
		shake_container.position.x = shake_base_position.x + offset_x
	else:
		shake_container.position = shake_base_position
	# VIDAS
	_update_hearts()
	# --- PÉRDIDA DE CORAZÓN ---
	if last_lives >= 0 and player.lives < last_lives:
		_trigger_heart_loss(player.lives)

	last_lives = player.lives

func _trigger_heart_loss(index: int):
	if index < 0 or index >= vidas_ui.get_child_count():
		return

	var heart := vidas_ui.get_child(index)

	heart.modulate = Color(1.0, 0.2, 0.2)
	await get_tree().create_timer(0.08).timeout
	heart.modulate = Color.WHITE

func _update_hearts():
	if player == null:
		return

	for i in range(vidas_ui.get_child_count()):
		var heart := vidas_ui.get_child(i)
		if i < player.lives:
			heart.texture = full_heart
		else:
			heart.texture = empty_heart
