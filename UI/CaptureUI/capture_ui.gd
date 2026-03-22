extends CanvasLayer

@onready var captor_bar: ProgressBar = $Container/CaptorBar
@onready var prey_bar: ProgressBar = $Container/PreyBar

var captor_stamina: CaptureStaminaComponent = null
var prey_stamina: CaptureStaminaComponent   = null

func _ready() -> void:
	# Oculto por defecto
	visible = false
	EventBus.event_emitted.connect(_on_event_emitted)

func _on_event_emitted(event_id: String, payload: Dictionary, _metadata: Dictionary) -> void:
	match event_id:
		"EVT_INTENTO_CAPTURA":
			_show_bars(payload.get("captor_id", ""), payload.get("prey_id", ""))
		"EVT_CAPTURA_EXITOSA", \
		"EVT_INTENTO_CAPTURA_FALLIDO", \
		"EVT_LIBERACION_FORZADA", \
		"EVT_JUGADOR_CANCELA_CAZA":
			_hide_bars()

func _show_bars(captor_id: String, prey_id: String) -> void:
	# Buscar nodos por nombre
	var captor := _find_node_by_name(captor_id)
	var prey   := _find_node_by_name(prey_id)

	if captor == null or prey == null:
		push_warning("CaptureUI: no se encontraron captor o presa")
		return

	captor_stamina = captor.get_node_or_null("CaptureStaminaComponent")
	prey_stamina   = prey.get_node_or_null("CaptureStaminaComponent")

	if captor_stamina == null or prey_stamina == null:
		push_warning("CaptureUI: falta CaptureStaminaComponent")
		return

	# Configurar barras
	captor_bar.max_value = captor_stamina.get_capture_stamina_max()
	captor_bar.value     = captor_stamina.get_capture_stamina()
	prey_bar.max_value   = prey_stamina.get_capture_stamina_max()
	prey_bar.value       = prey_stamina.get_capture_stamina()

	# Conectar señales
	if not captor_stamina.capture_stamina_changed.is_connected(_on_captor_stamina_changed):
		captor_stamina.capture_stamina_changed.connect(_on_captor_stamina_changed)
	if not prey_stamina.capture_stamina_changed.is_connected(_on_prey_stamina_changed):
		prey_stamina.capture_stamina_changed.connect(_on_prey_stamina_changed)

	visible = true

func _hide_bars() -> void:
	if captor_stamina and captor_stamina.capture_stamina_changed.is_connected(_on_captor_stamina_changed):
		captor_stamina.capture_stamina_changed.disconnect(_on_captor_stamina_changed)
	if prey_stamina and prey_stamina.capture_stamina_changed.is_connected(_on_prey_stamina_changed):
		prey_stamina.capture_stamina_changed.disconnect(_on_prey_stamina_changed)

	captor_stamina = null
	prey_stamina   = null
	visible = false

func _on_captor_stamina_changed(current: float, max_val: float) -> void:
	captor_bar.max_value = max_val
	captor_bar.value     = current

func _on_prey_stamina_changed(current: float, max_val: float) -> void:
	prey_bar.max_value = max_val
	prey_bar.value     = current

func _find_node_by_name(node_name: String) -> Node:
	# Busca en grupos conocidos
	for node in get_tree().get_nodes_in_group("Player"):
		if node.name == node_name:
			return node
	for node in get_tree().get_nodes_in_group("enemigo"):
		if node.name == node_name:
			return node
	return null
