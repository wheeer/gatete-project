extends Node

@onready var don_gato = $DonGato  # Asume que DonGato es hijo de este nodo

func _ready() -> void:
	print("=== Iniciando prueba de snapshot del DonGato ===")
	print("=== DEBUG: Estructura de nodos de DonGato ===")
	_print_tree(don_gato, 0)
	print("=== FIN DEBUG ===\n")
	
	# Espera a que DonGato se inicialice
	await get_tree().process_frame
	
	# Toma un snapshot
	var factory = SnapshotFactory.new()
	var snapshot = factory.create_snapshot(don_gato)
	
	# Imprime los datos capturados
	print("Snapshot del DonGato:")
	print("  - ID: ", snapshot.entity_id)
	print("  - Salud: ", snapshot.health_current, " / ", snapshot.health_max)
	print("  - Postura: ", snapshot.posture_current, " / ", snapshot.posture_max)
	print("  - Corazones: ", snapshot.hearts_current)
	print("  - Posición: ", snapshot.position)
	print("=== Prueba completada ===")
	
func _print_tree(node: Node, indent: int) -> void:
	var prefix = "  ".repeat(indent)
	print(prefix + "- " + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_tree(child, indent + 1)
