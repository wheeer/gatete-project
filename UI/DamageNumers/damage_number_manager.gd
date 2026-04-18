# UI/DamageNumbers/damage_number_manager.gd
class_name DamageNumberManager
extends Node

## Escena precargada del número flotante
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://UI/DamageNumers/damage_number.tscn")
func _ready() -> void:
	print("DamageNumberManager inicializado ✅")
	EventBus.event_emitted.connect(_on_event_emitted)

func _on_event_emitted(event_id: String, payload: Dictionary, _metadata: Dictionary) -> void:
	print("DamageNumberManager recibió: ", event_id)
	if event_id != "EVT_RECIBIR_GOLPE":
		return

	var health_damage: float  = float(payload.get("damage_dealt", 0.0))
	var posture_damage: float = float(payload.get("posture_damage_dealt", 0.0))
	var is_critical: bool     = bool(payload.get("is_critical", false))
	var is_heavy_hit: bool    = bool(payload.get("is_heavy_hit", false))
	var health_max: float     = float(payload.get("health_max", 100.0))
	var target_id: String     = payload.get("target_id", "")

	## Solo mostrar si hay daño real
	if health_damage <= 0.0 and posture_damage <= 0.0:
		return

	## Buscar la posición 3D del receptor para proyectar a pantalla
	var target := _find_target(target_id)
	if target == null:
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	## Offset aleatorio horizontal para que no se apilen cuando hay varios golpes
	var offset_x: float = randf_range(-15.0, 15.0)
	var world_pos: Vector3 = target.global_position + Vector3(0.0, 1.8, 0.0)
	var screen_pos: Vector2 = camera.unproject_position(world_pos)
	screen_pos.x += offset_x

	## Instanciar y configurar
	var dmg_number := DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().current_scene.add_child(dmg_number)
	dmg_number.global_position = screen_pos
	dmg_number.setup(health_damage, posture_damage, is_critical, is_heavy_hit, health_max)

func _find_target(target_id: String) -> Node3D:
	for node in get_tree().get_nodes_in_group("Player"):
		if node.name == target_id:
			return node as Node3D
	for node in get_tree().get_nodes_in_group("enemigo"):
		if node.name == target_id:
			return node as Node3D
	return null
