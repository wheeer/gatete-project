## damage_resolver.gd — versión corregida

class_name DamageResolver
extends Node

const DEFAULT_POSTURE_DAMAGE_RATIO = 0.5

func _ready() -> void:
	print("DamageResolver inicializado")

func resolve(damage_context: Dictionary, snapshot: EntitySnapshot) -> Dictionary:
	var verdict := {
		"delta_health": 0.0,
		"delta_posture": 0.0,
		"delta_hearts": 0,
		"generated_events": [],
		"resulting_physical_state": "",
		"delta_grab_stamina": 0.0,
		"delta_capture_resistance": 0.0
	}

	if damage_context == null or snapshot == null:
		push_error("DamageResolver: DamageContext o Snapshot es null")
		return verdict

	# La fuente es el primer discriminador del sistema — sección 19.1
	var source: String = damage_context.get("source", "DESCONOCIDO")

	# === PASO 1: Evaluar contexto de excepción ===
	if snapshot.is_capturing or snapshot.is_captured:
		# TODO: reglas especiales de captura (sección 17)
		pass

	# === PASO 2: Aplicar modificadores — críticos, bonificaciones ===
	var damage_base: float = float(damage_context.get("damage_base", 0.0))
	var is_critical: bool = bool(damage_context.get("is_critical", false))
	var is_heavy_hit: bool = bool(damage_context.get("is_heavy_hit", false))
	var crit_multiplier: float = float(damage_context.get("crit_health_multiplier", 1.5))

	if is_critical:
		damage_base *= crit_multiplier

	# === PASO 3: Resolver daño a vida según quién recibe ===
	var health_damage: float = 0.0
	var hearts_consumed: int = 0

	if source == "ENEMIGO":
		# El jugador está recibiendo daño — aplica lógica de 9 Vidas
		var hearts_current: int = snapshot.hearts_current
		if hearts_current > 0:
			hearts_consumed = 1
			# Con corazones: daño reducido a vida (el corazón absorbe)
			health_damage = damage_base * 0.15  # daño residual mínimo
		else:
			# Sin corazones: daño real completo
			health_damage = damage_base
	else:
		# El enemigo está recibiendo daño — sin sistema de vidas
		health_damage = damage_base

	verdict["delta_health"] = -health_damage
	verdict["delta_hearts"] = -hearts_consumed

	# === PASO 4: Resolver daño a postura ===
	var posture_damage_base: float = float(damage_context.get("posture_damage_base", damage_base * DEFAULT_POSTURE_DAMAGE_RATIO))

	if is_critical:
		var crit_posture_multiplier: float = float(damage_context.get("crit_posture_multiplier", 2.0))
		posture_damage_base *= crit_posture_multiplier

	verdict["delta_posture"] = -posture_damage_base

	# === PASO 5: Evaluar estados físicos resultantes ===
	var new_posture: float = snapshot.posture_current + verdict["delta_posture"]

	if snapshot.posture_current > 0 and new_posture <= 0.0:
		verdict["resulting_physical_state"] = "POSTURE_BROKEN"
		verdict["generated_events"].append({
			"event_id": "EVT_POSTURA_ROTA",
			"payload": {
				"target_id": snapshot.entity_id,
				"remaining_posture": new_posture
			}
		})

	# === PASO 6: Impulsos psicológicos — SOLO para enemigos (sección 19.4) ===
	# Solo se generan cuando el jugador golpea al enemigo
	# TODO: implementar PsychologyComponent (Bloque 4 del MVP)

	# === PASO 7: Emitir eventos según fuente — sección ENUM_EVENTS ===

	# EVT_RECIBIR_GOLPE: universal, siempre se emite
	verdict["generated_events"].append({
		"event_id": "EVT_RECIBIR_GOLPE",
		"payload": {
			"target_id": snapshot.entity_id,
			"damage_dealt": health_damage,
			"posture_damage_dealt": posture_damage_base,
			"is_critical": is_critical,
			"source": source
		}
	})

	if source == "JUGADOR":
		# Eventos exclusivos: jugador golpea a enemigo
		if is_critical:
			# EVT_GOLPE_CRITICO_RECIBIDO: feed al sistema psicológico del enemigo
			verdict["generated_events"].append({
				"event_id": "EVT_GOLPE_CRITICO_RECIBIDO",
				"payload": {
					"target_id": snapshot.entity_id,
					"damage": damage_base
				}
			})

	elif source == "ENEMIGO":
		# Eventos exclusivos: enemigo golpea al jugador
		if is_heavy_hit:
			# EVT_GOLPE_FUERTE_RECIBIDO: activa TIME_STOP en el jugador (sección 13)
			verdict["generated_events"].append({
				"event_id": "EVT_GOLPE_FUERTE_RECIBIDO",
				"payload": {
					"target_id": snapshot.entity_id,
					"health_damage": health_damage,
					"impulse_strength": float(damage_context.get("impulse_strength", 0.0))
				}
			})
		if hearts_consumed > 0:
			verdict["generated_events"].append({
				"event_id": "EVT_CORAZON_PERDIDO",
				"payload": {
					"target_id": snapshot.entity_id,
					"hearts_remaining": snapshot.hearts_current - hearts_consumed
				}
			})

	# === PASO 8: Recompensas y penalizaciones ===
	# TODO: integrar con CaptureResolver (sección 17.5)

	return verdict

func emit_verdict_events(verdict: Dictionary) -> void:
	for event_data in verdict["generated_events"]:
		var event_id: String = event_data.get("event_id", "")
		var payload: Dictionary = event_data.get("payload", {})
		if event_id != "":
			EventBus.emit_event(event_id, payload, {"priority": 10})
