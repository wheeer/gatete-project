extends Node

@onready var don_gato = $DonGato
var damage_resolver: DamageResolver
var snapshot_factory: SnapshotFactory

func _ready() -> void:
	print("\n=== PRUEBA DE DAMAGE RESOLVER ===\n")
	
	# Inicializar sistemas
	damage_resolver = DamageResolver.new()
	snapshot_factory = SnapshotFactory.new()
	
	# Esperar a que DonGato esté listo
	await get_tree().process_frame
	
	# Tomar snapshot inicial
	var initial_snapshot = snapshot_factory.create_snapshot(don_gato)
	print("SNAPSHOT INICIAL:")
	print("  Salud: %.1f / %.1f" % [initial_snapshot.health_current, initial_snapshot.health_max])
	print("  Postura: %.1f / %.1f" % [initial_snapshot.posture_current, initial_snapshot.posture_max])
	print("  Corazones: %d\n" % initial_snapshot.hearts_current)
	
	# --- TEST 1: Golpe normal ---
	print("--- TEST 1: Golpe normal (30 daño) ---")
	var damage_context_1 = {
		"damage_base": 30.0,
		"posture_damage_base": 15.0,
		"is_critical": false
	}
	var verdict_1 = damage_resolver.resolve(damage_context_1, initial_snapshot)
	damage_resolver.emit_verdict_events(verdict_1)
	
	# Simular aplicación del daño
	var health_after_1 = initial_snapshot.health_current + verdict_1["delta_health"]
	var posture_after_1 = initial_snapshot.posture_current + verdict_1["delta_posture"]
	var hearts_after_1 = initial_snapshot.hearts_current + verdict_1["delta_hearts"]
	
	print("DESPUÉS del golpe normal:")
	print("  Salud: %.1f (cambio: %.1f)" % [health_after_1, verdict_1["delta_health"]])
	print("  Postura: %.1f (cambio: %.1f)" % [posture_after_1, verdict_1["delta_posture"]])
	print("  Corazones: %d (cambio: %d)\n" % [hearts_after_1, verdict_1["delta_hearts"]])
	
	# --- TEST 2: Golpe crítico ---
	print("--- TEST 2: Golpe crítico (50 daño base, x1.5 multiplicador) ---")
	var damage_context_2 = {
		"damage_base": 50.0,
		"posture_damage_base": 25.0,
		"is_critical": true,
		"crit_health_multiplier": 1.5,
		"crit_posture_multiplier": 2.0
	}
	var snapshot_2 = snapshot_factory.create_snapshot(don_gato)
	var verdict_2 = damage_resolver.resolve(damage_context_2, snapshot_2)
	damage_resolver.emit_verdict_events(verdict_2)
	
	var health_after_2 = snapshot_2.health_current + verdict_2["delta_health"]
	var posture_after_2 = snapshot_2.posture_current + verdict_2["delta_posture"]
	var hearts_after_2 = snapshot_2.hearts_current + verdict_2["delta_hearts"]
	
	print("DESPUÉS del golpe crítico:")
	print("  Salud: %.1f (cambio: %.1f)" % [health_after_2, verdict_2["delta_health"]])
	print("  Postura: %.1f (cambio: %.1f)" % [posture_after_2, verdict_2["delta_posture"]])
	print("  Corazones: %d (cambio: %d)\n" % [hearts_after_2, verdict_2["delta_hearts"]])
	
	print("=== FIN PRUEBA ===\n")
