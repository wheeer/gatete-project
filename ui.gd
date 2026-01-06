extends Control

@onready var life_bar: ProgressBar = $LifeBar
@onready var posture_bar: ProgressBar = $PostureBar
@onready var vidas_ui: HBoxContainer = $Vidas

@export var full_heart: Texture2D
@export var empty_heart: Texture2D

var player: Node = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	_update_hearts()

func _process(_delta):
	if player == null:
		return

	# VIDA
	life_bar.max_value = player.max_health
	life_bar.value = player.health

	# COMPOSTURA
	posture_bar.max_value = player.max_posture
	posture_bar.value = player.posture

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
