extends Control

@onready var life_bar: ProgressBar = $LifeBar
@onready var posture_bar: ProgressBar = $PostureBar

var player: Node = null

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if player == null:
		return

	# VIDA
	life_bar.max_value = player.max_health
	life_bar.value = player.health

	# COMPOSTURA
	posture_bar.max_value = player.max_posture
	posture_bar.value = player.posture
