extends Node
class_name DonGatoTargeting

var body: CharacterBody3D
var current_target: Node3D = null
var targets: Array[Node3D] = []
var is_locked: bool = false

const TARGET_RADIUS := 25.0

func setup(_body: CharacterBody3D) -> void:
	body = _body

func physics_update() -> void:
	if not is_locked:
		return
	
	if current_target and current_target.is_inside_tree():
		var target_pos = current_target.global_position
		target_pos.y = body.global_position.y
		body.look_at(target_pos, Vector3.UP)
	else:
		_switch_to_next_available_target()

func _switch_to_next_available_target():
	
	# Apagar marcador del anterior si aún existe referencia
	if current_target and current_target.has_method("set_targeted"):
		current_target.set_targeted(false)
	
	_refresh_targets()
	
	if targets.is_empty():
		_unlock()
		return
	
	current_target = targets[0]
	is_locked = true
	
	if current_target.has_method("set_targeted"):
		current_target.set_targeted(true)

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("look_on"):
		if is_locked:
			_unlock()
		else:
			_lock_closest()
	
	if not is_locked:
		return
	
	if event.is_action_pressed("target_next"):
		_cycle_target(1)
	
	if event.is_action_pressed("target_prev"):
		_cycle_target(-1)
		
func _refresh_targets():
	targets.clear()
	
	for node in get_tree().get_nodes_in_group("targetable"):
		if not node.is_inside_tree():
			continue
		
		var dist = body.global_position.distance_to(node.global_position)
		
		if dist <= TARGET_RADIUS:
			targets.append(node)
	
	targets.sort_custom(func(a,b):
		return body.global_position.distance_to(a.global_position) < body.global_position.distance_to(b.global_position)
		)
		
func _lock_closest():
	_refresh_targets()
	
	if targets.is_empty():
		return
	
	current_target = targets[0]
	is_locked = true
	
	if current_target.has_method("set_targeted"):
		current_target.set_targeted(true)
	
func _cycle_target(direction: int):
	if targets.is_empty():
		return
	
	var index = targets.find(current_target)
	
	# Apagar marcador anterior
	if current_target and current_target.has_method("set_targeted"):
		current_target.set_targeted(false)
	
	if index == -1:
		current_target = targets[0]
	else:
		index += direction
		
		if index >= targets.size():
			index = 0
		elif index < 0:
			index = targets.size() - 1
		
		current_target = targets[index]
	
	# Encender marcador nuevo
	if current_target and current_target.has_method("set_targeted"):
		current_target.set_targeted(true)

func is_locked_on() -> bool:
	return is_locked

func _unlock():
	if current_target and current_target.has_method("set_targeted"):
		current_target.set_targeted(false)
	
	is_locked = false
	current_target = null
