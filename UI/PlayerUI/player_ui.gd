extends Control

# === REFERENCIAS A NODOS DE UI ===
@onready var life_bar: ProgressBar = $ShakeContainer/LifeBar
@onready var posture_bar: ProgressBar = $ShakeContainer/PostureBar
@onready var vidas_ui: HBoxContainer = $ShakeContainer/Vidas
@onready var shake_container: Control = $ShakeContainer

@export var full_heart: Texture2D
@export var empty_heart: Texture2D

# === CONSTANTES VISUALES ===
const POSTURE_FLASH_DURATION  := 0.12
const POSTURE_BREAK_COLOR     := Color(0.7, 0.3, 1.0)  # violeta
const LIFE_FLASH_DURATION     := 0.08
const LIFE_FLASH_COLOR        := Color(1.0, 0.1, 0.1)
const LIFE_SHAKE_DURATION     := 0.15
const LIFE_SHAKE_STRENGTH     := 6.0
const LIFE_SAFE_COLOR         := Color(0.2, 0.9, 0.3)   # verde
const LIFE_WARN_COLOR         := Color(1.0, 0.7, 0.2)   # amarillo
const LIFE_DANGER_COLOR       := Color(1.0, 0.25, 0.25) # rojo

# === ESTADO INTERNO DE ANIMACIONES ===
# Estas variables solo existen para las animaciones de shake y flash
# No guardan datos del jugador — eso lo hacen los componentes
var life_shake_timer: float = 0.0
var life_flash_timer: float = 0.0
var posture_flash_timer: float = 0.0
var shake_base_position: Vector2

func _ready() -> void:
	shake_base_position = shake_container.position

	# Buscamos al jugador en el grupo "player"
	var player := get_tree().get_first_node_in_group("player") as DonGatoController
	if player == null:
		push_error("PlayerUI: no se encontró al jugador en el grupo 'player'")
		return

	# === CONECTAR SEÑALES DE COMPONENTES ===
	# Así la UI reacciona a cambios, en lugar de preguntar cada frame
	
	# Vida — conectamos a la señal de DonGatoHealth
	var health_comp := player.health_component as DonGatoHealth
	health_comp.health_changed.connect(_on_health_changed)
	# Pedimos los valores iniciales para que la barra no empiece en 0
	_on_health_changed(health_comp.current_health, health_comp.max_health)
	
	# Postura — conectamos a las señales de DonGatoPosture
	var posture_comp := player.posture_component as DonGatoPosture
	posture_comp.posture_changed.connect(_on_posture_changed)
	posture_comp.posture_broken.connect(_on_posture_broken)
	# Valores iniciales
	_on_posture_changed(posture_comp.current_posture, posture_comp.max_posture)
	
	# Corazones — conectamos a la señal nueva de DonGatoLives
	var lives_comp := player.lives_system as DonGatoLives
	lives_comp.hearts_changed.connect(_on_hearts_changed)
	# Valores iniciales
	_on_hearts_changed(lives_comp.hearts, lives_comp.max_hearts)


# =============================================
# === CALLBACKS — solo se llaman cuando hay cambio real
# =============================================

func _on_health_changed(current: float, max_val: float) -> void:
	# Actualizar la barra
	life_bar.max_value = max_val
	life_bar.value = current

	# Cambiar color según porcentaje de vida
	var ratio := current / max_val
	if ratio > 0.6:
		life_bar.modulate = LIFE_SAFE_COLOR
	elif ratio > 0.3:
		life_bar.modulate = LIFE_WARN_COLOR
	else:
		life_bar.modulate = LIFE_DANGER_COLOR

	# Disparar animaciones de daño
		life_flash_timer = LIFE_FLASH_DURATION
		life_shake_timer = LIFE_SHAKE_DURATION

func _on_posture_changed(current: float, max_val: float) -> void:
	posture_bar.max_value = max_val
	posture_bar.value = current


func _on_posture_broken() -> void:
	# Flash violeta al romperse la postura del jugador
	posture_flash_timer = POSTURE_FLASH_DURATION


func _on_hearts_changed(current: int, max_val: int) -> void:
	# Recorremos todos los corazones en la UI y asignamos la textura correcta
	for i in range(vidas_ui.get_child_count()):
		var heart := vidas_ui.get_child(i)
		if i < current:
			heart.texture = full_heart   # corazón lleno
		else:
			heart.texture = empty_heart  # corazón vacío

	# Animación de pérdida: parpadeo rojo en el corazón que se acaba de perder
	# "current" ya tiene el nuevo valor, entonces el corazón perdido está en índice "current"
	if current < max_val:
		_trigger_heart_loss_animation(current)


# =============================================
# === _process — SOLO para animaciones de tiempo
# Nada de leer datos del jugador aquí
# =============================================

func _process(delta: float) -> void:
	
	# --- Flash de vida ---
	if life_flash_timer > 0.0:
		life_flash_timer -= delta
		life_bar.modulate = LIFE_FLASH_COLOR
	
	# --- Flash de postura rota ---
	if posture_flash_timer > 0.0:
		posture_flash_timer -= delta
		posture_bar.modulate = POSTURE_BREAK_COLOR
	else:
		posture_bar.modulate = Color.WHITE
		
	# --- Shake de la UI al recibir daño ---
	if life_shake_timer > 0.0:
		life_shake_timer -= delta
		var offset_x := randf_range(-LIFE_SHAKE_STRENGTH, LIFE_SHAKE_STRENGTH)
		shake_container.position.x = shake_base_position.x + offset_x
	else:
		shake_container.position = shake_base_position

# =============================================
# === ANIMACIÓN AUXILIAR
# =============================================

func _trigger_heart_loss_animation(lost_index: int) -> void:
	# "lost_index" es el índice del corazón que se acaba de perder
	if lost_index < 0 or lost_index >= vidas_ui.get_child_count():
		return

	var heart := vidas_ui.get_child(lost_index)
	heart.modulate = Color(1.0, 0.2, 0.2)  # rojo
	await get_tree().create_timer(0.08).timeout
	heart.modulate = Color.WHITE
