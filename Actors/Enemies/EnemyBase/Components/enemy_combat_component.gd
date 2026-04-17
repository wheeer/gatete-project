extends Node
class_name EnemyCombatComponent

# === Rangos ===
@export var detection_range: float = 12.0
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 2.0

# === Daño que inflige ===
@export var damage_base: float = 20.0
@export var posture_damage_base: float = 10.0
@export var can_be_heavy: bool = true

# === Estado interno ===
var cooldown_timer: float = 0.0
var combat_mediator: CombatMediator

var health: HealthComponent
var posture: PostureComponent
var enemy_base: EnemyBase

func initialize(_enemy: EnemyBase, _health: HealthComponent, _posture: PostureComponent) -> void:
	enemy_base = _enemy
	health = _health
	posture = _posture

	combat_mediator = CombatMediator.new()
	combat_mediator.initialize()

func _process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	# No actuar si está stunned o muerto
	if enemy_base.stun.is_stunned():
		return

	var player := _get_player()
	if player == null:
		return
	
	# Guard: no atacar si el jugador ya está muerto
	var player_health := player.get_node_or_null("HealthComponent")
	if player_health and not player_health.is_alive():
		enemy_base.movement.stop()
		return
		
	var dist: float = enemy_base.global_position.distance_to(player.global_position)

	if dist <= attack_range:
		# Detener movimiento y atacar
		enemy_base.movement.stop()
		_try_attack(player)
	elif dist <= detection_range:
		# Perseguir al jugador
		var dir: Vector3 = (player.global_position - enemy_base.global_position).normalized()
		dir.y = 0.0
		enemy_base.movement.set_move_direction(dir)
	else:
		# Fuera de rango — quieto
		enemy_base.movement.stop()

func _try_attack(player: Node) -> void:
	if cooldown_timer > 0.0:
		return
	cooldown_timer = attack_cooldown

	var hit_data := {
		"damage_base":         damage_base,
		"posture_damage_base": posture_damage_base,
		"can_be_heavy":        can_be_heavy,
		"impulse_strength":    12.0 if can_be_heavy else 0.0,
		"source_position":     enemy_base.global_position
	}

	combat_mediator.process_enemy_attack(enemy_base, player, hit_data)

func _get_player() -> Node:
	var players := get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		return null
	return players[0]

## DEPRECATED — el daño va por CombatMediator
func receive_hit(_hit_data: Dictionary) -> void:
	push_error("EnemyCombatComponent.receive_hit() llamado directamente en '%s'. Usar CombatMediator." % enemy_base.name)
