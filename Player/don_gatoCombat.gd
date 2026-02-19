extends Node
class_name DonGatoCombat

signal attack_started
signal attack_finished

@export var attack_damage: float = 25.0
@export var startup_time: float = 0.08
@export var active_time: float = 0.05
@export var recovery_time: float = 0.15

@export var attack_cooldown: float = 0.28
@export var attack_stamina_cost: float = 15.0


enum AttackPhase {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY
}
var current_phase: AttackPhase = AttackPhase.NONE

var stats: DonGatoStats

var body: CharacterBody3D
var attack_area: Area3D

var is_attacking: bool = false
var cooldown_timer: float = 0.0
var attack_timer: float = 0.0
var already_hit: bool = false


func _ready() -> void:
	pass

func setup(_body: CharacterBody3D, _attack_area: Area3D, _stats: DonGatoStats) -> void:
	body = _body
	attack_area = _attack_area
	stats = _stats
	
	attack_area.monitoring = false
	attack_area.area_entered.connect(_on_attack_area_area_entered)
	
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

func try_attack() -> void:
	if is_attacking:
		return
	
	if cooldown_timer > 0:
		return
	
	if not stats.spend(attack_stamina_cost):
		return
	
	_start_attack()

func _start_attack() -> void:
	is_attacking = true
	current_phase = AttackPhase.STARTUP
	attack_timer = startup_time
	cooldown_timer = attack_cooldown
	already_hit = false
	
	emit_signal("attack_started")

func _on_attack_area_area_entered(area: Area3D) -> void:
	print("Golpe en fase:", current_phase)
	var enemy = area.get_parent()
	
	if enemy.has_method("take_damage"):
		enemy.take_damage(attack_damage)

func _end_attack() -> void:
	is_attacking = false
	current_phase = AttackPhase.NONE
	attack_area.monitoring = false
	emit_signal("attack_finished")
