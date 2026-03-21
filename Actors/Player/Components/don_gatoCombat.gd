extends Node
class_name DonGatoCombat

signal attack_started
signal attack_finished

@export var startup_time: float = 0.08
@export var active_time: float = 0.05
@export var recovery_time: float = 0.15

@export var attack_cooldown: float = 0.28
@export var attack_stamina_cost: float = 15.0

@export var combo_flow_duration: float = 0.45
var combo_index: int = 0
@export var combo_reset_time: float = 0.6
var combo_reset_timer: float = 0.0

@export var light_damage_min: float = 10.0
@export var light_damage_max: float = 20.0

@export var medium_damage_min: float = 15.0
@export var medium_damage_max: float = 25.0

@export var heavy_damage_min: float = 20.0
@export var heavy_damage_max: float = 30.0

@export var crit_chance: float = 0.15
@export var crit_multiplier: float = 1.5

var combat_mediator: CombatMediator
var capture_resolver: CaptureResolver
var is_capturing: bool = false

enum AttackPhase {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY
}
enum HitStrength {
	LIGHT,
	MEDIUM,
	HEAVY,
	CRITICAL
}

var current_phase: AttackPhase = AttackPhase.NONE
var stats: DonGatoStats

var body: CharacterBody3D
var attack_area: Area3D

var is_attacking: bool = false
var cooldown_timer: float = 0.0
var attack_timer: float = 0.0
var already_hit: bool = false

var combo_flow_timer: float = 0.0

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if is_attacking:
		attack_timer -= delta
		
		if attack_timer <= 0:
			match current_phase:
				AttackPhase.STARTUP:
					current_phase = AttackPhase.ACTIVE
					attack_timer = active_time
					attack_area.monitoring = true
				
				AttackPhase.ACTIVE:
					current_phase = AttackPhase.RECOVERY
					attack_timer = recovery_time
					attack_area.monitoring = false
				
				AttackPhase.RECOVERY:
					_end_attack()
					
	if combo_flow_timer > 0:
		combo_flow_timer -= delta
	
	if combo_reset_timer > 0:
		combo_reset_timer -= delta
	else:
		combo_index = 0

func is_in_combo_flow() -> bool:
	return combo_flow_timer > 0

func try_attack() -> bool:
	if is_attacking:
		return false
	
	if cooldown_timer > 0:
		return false
	
	if not stats.spend(attack_stamina_cost):
		return false
	
	# --- LÓGICA DE COMBO ---
	if combo_index == 0:
		combo_index = 1
	elif combo_index < 3:
		combo_index += 1
	else:
		combo_index = 1
	
	combo_reset_timer = combo_reset_time
	
	print("Combo:", combo_index)
	
	_start_attack()
	return true

func _start_attack() -> void:
	is_attacking = true
	current_phase = AttackPhase.STARTUP
	attack_timer = startup_time
	cooldown_timer = attack_cooldown
	already_hit = false
	combo_flow_timer = combo_flow_duration
	attack_started.emit()

func setup(_body: CharacterBody3D, _attack_area: Area3D, _stats: DonGatoStats) -> void:
	body = _body
	attack_area = _attack_area
	stats = _stats
	
	combat_mediator = CombatMediator.new()
	combat_mediator.initialize()
	
	attack_area.monitoring = false
	attack_area.area_entered.connect(_on_attack_area_area_entered)
	
	capture_resolver = CaptureResolver.new()
	capture_resolver.capture_resolved.connect(_on_capture_resolved)
	add_child(capture_resolver)
	
func _on_attack_area_area_entered(area: Area3D) -> void:
	if current_phase != AttackPhase.ACTIVE:
		return
	
	if already_hit:
		return
	
	var enemy: Node = area.get_parent()
	
	if not is_instance_valid(enemy):
		return
	
	if not enemy.is_in_group("enemigo"):
		return
	
	var hit_data: Dictionary = {
		"damage": _roll_damage(),
		"strength": _get_hit_strength(),
		"combo_index": combo_index,
		"crit_chance": crit_chance,
		"crit_multiplier": crit_multiplier
	}
	
	combat_mediator.process_player_attack(body, enemy, hit_data)
	already_hit = true

func _end_attack() -> void:
	is_attacking = false
	current_phase = AttackPhase.NONE
	attack_area.monitoring = false
	attack_finished.emit()

func cancel_attack() -> void:
	if not is_attacking:
		return
	
	is_attacking = false
	current_phase = AttackPhase.NONE
	attack_area.monitoring = false
	attack_finished.emit()

func try_capture(target_override: Node = null) -> bool:
	print("🔍 try_capture() llamado | is_capturing: %s" % is_capturing)
	if is_capturing:
		return false

	var prey: Node = target_override
	if prey == null:
		prey = _find_capturable_enemy()
		
	var prey_name: String = "NINGUNA"
	if prey != null:
		prey_name = prey.name
	print("🔍 Presa encontrada: %s" % prey_name)
	
	if prey == null:
		return false

	is_capturing = true
	capture_resolver.start_capture(body, prey)
	return true
func update_capture(delta: float) -> void:
	if not is_capturing:
		return
	capture_resolver.update(delta)

func cancel_capture_attempt() -> void:
	if not is_capturing:
		return
	capture_resolver.cancel_capture()

func _find_capturable_enemy() -> Node:
	# Busca el enemigo en POSTURE_BROKEN más cercano dentro de rango
	const CAPTURE_RANGE := 2.5
	var closest: Node = null
	var closest_dist := CAPTURE_RANGE

	for node in get_tree().get_nodes_in_group("enemigo"):
		if not is_instance_valid(node):
			continue
		var state_machine := node.get_node_or_null("StateMachine") as EnemyStateMachine
		if state_machine == null:
			continue
		if not state_machine.is_in_state(EnemyStateMachine.PhysicalState.POSTURE_BROKEN):
			continue
		var dist := body.global_position.distance_to(node.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = node

	return closest

func _on_capture_resolved(result: String) -> void:
	is_capturing = false
	print("Captura terminó: %s" % result)

func _get_hit_strength() -> HitStrength:
	match combo_index:
		1:
			return HitStrength.LIGHT
		2:
			return HitStrength.MEDIUM
		3:
			return HitStrength.HEAVY
		_:
			return HitStrength.LIGHT

func _roll_damage() -> float:
	var min_dmg: float
	var max_dmg: float
	
	match combo_index:
		1:
			min_dmg = light_damage_min
			max_dmg = light_damage_max
		2:
			min_dmg = medium_damage_min
			max_dmg = medium_damage_max
		3:
			min_dmg = heavy_damage_min
			max_dmg = heavy_damage_max
		_:
			min_dmg = light_damage_min
			max_dmg = light_damage_max
	
	var dmg = randf_range(min_dmg, max_dmg)
	
	# ✗ NO aplicar crit aquí - lo hace CombatMediator
	# if randf() <= local_crit_chance:
	#	dmg *= local_crit_multiplier
	#	print("CRIT x", local_crit_multiplier)
	
	return dmg
