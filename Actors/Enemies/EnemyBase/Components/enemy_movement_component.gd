extends Node
class_name EnemyMovementComponent

@export var move_speed: float = 3.5

var enemy: CharacterBody3D
var velocity: Vector3 = Vector3.ZERO
var move_direction: Vector3 = Vector3.ZERO

func initialize(_owner: CharacterBody3D) -> void:
	enemy = _owner

func set_move_direction(direction: Vector3) -> void:
	move_direction = direction.normalized()

func stop() -> void:
	move_direction = Vector3.ZERO

func physics_process(_delta: float) -> void:
	if enemy == null:
		return
	
	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed
	
	enemy.velocity = velocity
	enemy.move_and_slide()
