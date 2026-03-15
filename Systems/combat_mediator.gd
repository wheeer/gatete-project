class_name CombatMediator
extends Node

var damage_resolver: DamageResolver
var snapshot_factory: SnapshotFactory

## Inicialización manual (llamar esto en lugar de confiar en _ready)
func initialize() -> void:
	damage_resolver = DamageResolver.new()
	snapshot_factory = SnapshotFactory.new()
	print("CombatMediator inicializado")

func _ready() -> void:
	if damage_resolver == null:
		initialize()

## Procesa un ataque del jugador contra un enemigo
func process_player_attack(player: Node, enemy: Node, hit_data: Dictionary) -> void:
	if snapshot_factory == null:
		initialize()

	print("\n=== COMBATE: Ataque del jugador ===")

	# Crear snapshot del enemigo ANTES del daño
	var enemy_snapshot = snapshot_factory.create_snapshot(enemy)

	# Construir damage_context desde hit_data
	var damage_context = _build_damage_context_from_hit_data(hit_data, player)

	# Resolver daño
	var verdict = damage_resolver.resolve(damage_context, enemy_snapshot)

	# Asignar target_id a todos los eventos
	for event_data in verdict.get("generated_events", []):
		event_data["payload"]["target_id"] = enemy.name

	# Aplicar veredicto al enemigo
	_apply_verdict_to_entity(enemy, verdict)

	# Emitir eventos (con el target_id ya asignado)
	damage_resolver.emit_verdict_events(verdict)

## Construye un damage_context desde hit_data del jugador
func _build_damage_context_from_hit_data(hit_data: Dictionary, _player: Node) -> Dictionary:
	var damage_base = float(hit_data.get("damage", 15.0))
	var strength = hit_data.get("strength", 0)
	var combo_index = hit_data.get("combo_index", 1)

	# Determinar si es crítico
	var crit_chance: float = float(hit_data.get("crit_chance", 0.15))
	var crit_multiplier: float = float(hit_data.get("crit_multiplier", 1.5))
	var is_critical: bool = (combo_index == 3) and (randf() < crit_chance)

	# Posture damage basado en strength
	var posture_damage_base = _calculate_posture_damage_from_strength(strength)

	# Multiplicadores críticos
	var crit_health_multiplier: float = crit_multiplier if is_critical else 1.0
	var crit_posture_multiplier: float = crit_multiplier if is_critical else 1.0

	var context = {
		"damage_base": damage_base,
		"posture_damage_base": posture_damage_base,
		"is_critical": is_critical,
		"is_heavy_hit": false,  # El jugador no genera TIME STOP en el enemigo
		"crit_health_multiplier": crit_health_multiplier,
		"crit_posture_multiplier": crit_posture_multiplier,
		"combo_index": combo_index,
		"source": "JUGADOR"
	}

	print("DEBUG: Damage Context creado:")
	print("  - Base: %.1f | Posture: %.1f" % [damage_base, posture_damage_base])
	print("  - Crítico: %s | Combo: %d" % [is_critical, combo_index])

	return context

## Calcula daño a postura según strength del golpe
func _calculate_posture_damage_from_strength(strength: int) -> float:
	match strength:
		0:  # LIGHT
			return randf_range(15, 25)
		1:  # MEDIUM
			return randf_range(25, 35)
		2:  # HEAVY
			return randf_range(40, 55)
		#3:  # CRITICAL reservado para habilidades (no alcanzable desde combo)
	return 15.0

## Aplica el veredicto del DamageResolver a los componentes reales del enemigo
func _apply_verdict_to_entity(entity: Node, verdict: Dictionary) -> void:
	print("\n=== APLICANDO VEREDICTO ===")

	var delta_health = verdict.get("delta_health", 0.0)
	if delta_health < 0.0:
		var health_component = entity.get_node_or_null("HealthComponent")
		if health_component and health_component.has_method("apply_damage"):
			health_component.apply_damage(-delta_health)
			print("✓ Daño a salud: %.1f" % (-delta_health))

	var delta_posture = verdict.get("delta_posture", 0.0)
	if delta_posture < 0.0:
		var posture_component = entity.get_node_or_null("PostureComponent")
		if posture_component and posture_component.has_method("apply_posture_damage"):
			posture_component.apply_posture_damage(-delta_posture)
			print("✓ Daño a postura: %.1f" % (-delta_posture))

	var new_state = verdict.get("resulting_physical_state", "")
	if new_state != "":
		print("✓ Nuevo estado físico: %s" % new_state)
		
	var delta_hearts: int = verdict.get("delta_hearts", 0)
	if delta_hearts < 0:
		var lives_node = entity.get_node_or_null("LivesSystem")
		if lives_node and lives_node.has_method("consume_heart"):
			lives_node.consume_heart()
			print("✓ Corazón consumido")
	print("=== FIN APLICACIÓN ===\n")

	# Ejecutar muerte DESPUÉS del cierre
	if new_state == "DEAD" and entity.has_method("die"):
		entity.die()
