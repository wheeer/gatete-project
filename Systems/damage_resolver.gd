class_name DamageResolver
extends Node

# Constantes del sistema
const DEFAULT_POSTURE_DAMAGE_RATIO = 0.5  # 50% del daño va a postura por defecto

func _ready() -> void:
	print("DamageResolver inicializado")

## Método principal: resuelve daño según El Nuevo Testamento (sección 19.4)
## Retorna un Dictionary con el veredicto de daño (DamageVerdict)
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
		print("ERROR: DamageContext o Snapshot es null")
		return verdict

	# === PASO 1: Evaluar contexto de excepción ===
	var is_capturing = snapshot.is_capturing
	var is_captured = snapshot.is_captured
	
	if is_capturing or is_captured:
		print("DEBUG: Contexto especial (captura). Modificando resolución...")
		# TODO: Implementar reglas especiales de captura

	# === PASO 2: Aplicar modificadores (stats, críticos, bonificaciones) ===
	var damage_base = float(damage_context.get("damage_base", 0.0))
	var is_critical = bool(damage_context.get("is_critical", false))
	var crit_multiplier = float(damage_context.get("crit_health_multiplier", 1.5))
	
	if is_critical:
		damage_base *= crit_multiplier
		print("DEBUG: Golpe crítico aplicado. Daño modificado a: %.1f" % damage_base)

	# === PASO 3: Resolver daño a vida (Sistema de 9 Vidas) ===
	var hearts_current = snapshot.hearts_current
	var health_damage = 0.0
	var hearts_consumed = 0
	
	if hearts_current > 0:
		# Hay corazones disponibles: consumir 1 corazón
		hearts_consumed = 1
		print("DEBUG: Corazón consumido. Corazones restantes: %d" % (hearts_current - 1))
	else:
		# Sin corazones: aplicar daño completo a la vida
		health_damage = damage_base
		print("DEBUG: Sin corazones. Daño completo a vida: %.1f" % health_damage)

	verdict["delta_health"] = -health_damage
	verdict["delta_hearts"] = -hearts_consumed

	# === PASO 4: Resolver daño a postura ===
	var posture_damage_base = float(damage_context.get("posture_damage_base", damage_base * DEFAULT_POSTURE_DAMAGE_RATIO))
	
	if is_critical:
		var crit_posture_multiplier = float(damage_context.get("crit_posture_multiplier", 2.0))
		posture_damage_base *= crit_posture_multiplier

	verdict["delta_posture"] = -posture_damage_base
	print("DEBUG: Daño a postura: %.1f" % posture_damage_base)

	# === PASO 5: Evaluar estados físicos resultantes ===
	# ← CAMBIO AQUÍ: Solo romper postura si NO está ya roto
	var new_posture = snapshot.posture_current + verdict["delta_posture"]
	var _posture_broken = false
	
	# Verificar si ya está roto
	if snapshot.posture_current <= 0:
		print("DEBUG: Postura ya estaba rota, sin nueva ruptura")
	elif new_posture <= 0.0:  # ← Solo romper si estaba intacta
		_posture_broken = true
		verdict["resulting_physical_state"] = "POSTURE_BROKEN"
		verdict["generated_events"].append({
			"event_id": "EVT_POSTURA_ROTA",
			"payload": {
				"target_id": snapshot.entity_id,
				"remaining_posture": new_posture
			}
		})
		print("DEBUG: POSTURA ROTA")

	# === PASO 6: Generar impulsos psicológicos (solo enemigos) ===
	# TODO: Implementar cuando se tenga sistema de psicología enemiga

	# === PASO 7: Emitir eventos de gameplay ===
	# Evento principal: recibir golpe
	verdict["generated_events"].append({
		"event_id": "EVT_RECIBIR_GOLPE",
		"payload": {
			"target_id": snapshot.entity_id,
			"damage_dealt": health_damage,
			"posture_damage_dealt": posture_damage_base,
			"is_critical": is_critical,
			"hearts_consumed": hearts_consumed
		}
	})

	if is_critical:
		verdict["generated_events"].append({
			"event_id": "EVT_GOLPE_CRITICO_RECIBIDO",
			"payload": {
				"target_id": snapshot.entity_id,
				"damage": damage_base
			}
		})

	if health_damage > 0.0:
		verdict["generated_events"].append({
			"event_id": "EVT_GOLPE_FUERTE_RECIBIDO",
			"payload": {
				"target_id": snapshot.entity_id,
				"health_damage": health_damage
			}
		})

	# === PASO 8: Aplicar recompensas o penalizaciones ===
	# TODO: Implementar cuando se integre con captura/ejecución

	print("=== DamageVerdict ===")
	print("  Delta Health: %.1f" % verdict["delta_health"])
	print("  Delta Posture: %.1f" % verdict["delta_posture"])
	print("  Hearts Consumed: %d" % verdict["delta_hearts"])
	print("  Events: %d" % verdict["generated_events"].size())
	print("=====================\n")

	return verdict

## Método auxiliar: emitir todos los eventos del veredicto al EventBus
func emit_verdict_events(verdict: Dictionary) -> void:
	for event_data in verdict["generated_events"]:
		var event_id = event_data.get("event_id", "")
		var payload = event_data.get("payload", {})
		if event_id != "":
			EventBus.emit_event(event_id, payload, {"priority": 10})
			print("Evento emitido al EventBus: %s" % event_id)
