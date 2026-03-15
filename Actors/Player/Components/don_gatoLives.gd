extends Node
class_name DonGatoLives

signal hearts_changed(current: int, max_val: int)

var hearts: int = 9  # Sistema de 9 vidas (corazones)
var max_hearts: int = 9

func _ready() -> void:
	# Inicializa corazones al máximo
	hearts = max_hearts
	print("Lives/Hearts initialized: %d / %d" % [hearts, max_hearts])
	hearts_changed.emit(hearts, max_hearts)

func consume_heart() -> bool:
	if hearts > 0:
		hearts -= 1
		print("Heart consumed! Remaining: %d / %d" % [hearts, max_hearts])
		hearts_changed.emit(hearts, max_hearts)
		return true
	else:
		print("No hearts left!")
		return false

func restore_heart(amount: int = 1) -> void:
	hearts = mini(max_hearts, hearts + amount)
	print("Hearts restored: +%d | Total: %d / %d" % [amount, hearts, max_hearts])
	hearts_changed.emit(hearts, max_hearts)

func has_hearts() -> bool:
	return hearts > 0

func get_hearts() -> int:
	return hearts

func get_max_hearts() -> int:
	return max_hearts
