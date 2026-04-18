# UI/DamageNumbers/damage_number.gd
class_name DamageNumber
extends Node2D

## Duración total de la animación en segundos
const LIFETIME: float = 0.9
## Velocidad de subida en píxeles por segundo
const FLOAT_SPEED: float = 55.0
## Velocidad de subida del subíndice de postura
const POSTURE_OFFSET_Y: float = 12.0

var _timer: float = 0.0
var _life_label: Label
var _posture_label: Label

func setup(
	health_damage: float,
	posture_damage: float,
	_is_critical: bool,
	is_heavy_hit: bool,
	health_max: float
) -> void:

	var life_color: Color = _get_life_color(health_damage, health_max, is_heavy_hit)
	var life_text: String = "%d" % int(health_damage)
	var life_size: int = 28

	## Borde del número de vida — 4 sombras desplazadas en negro
	for offset in [Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1), Vector2(1,1)]:
		var shadow := Label.new()
		shadow.text = life_text
		shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shadow.add_theme_font_size_override("font_size", life_size)
		shadow.modulate = Color(0.0, 0.0, 0.0, 0.85)
		shadow.position = offset
		add_child(shadow)

	## Número principal de vida
	_life_label = Label.new()
	_life_label.text = life_text
	_life_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_life_label.add_theme_font_size_override("font_size", life_size)
	_life_label.modulate = life_color
	add_child(_life_label)

	## Daño a postura como subíndice
	if posture_damage > 0.0:
		var posture_text: String = "%d" % int(posture_damage)
		var posture_size: int = 12

		## Borde del subíndice
		for offset in [Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1), Vector2(1,1)]:
			var shadow := Label.new()
			shadow.text = posture_text
			shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			shadow.add_theme_font_size_override("font_size", posture_size)
			shadow.modulate = Color(0.0, 0.0, 0.0, 0.85)
			shadow.position = offset + Vector2(28.0, 16.0)
			add_child(shadow)

		## Subíndice de postura
		_posture_label = Label.new()
		_posture_label.text = posture_text
		_posture_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_posture_label.add_theme_font_size_override("font_size", posture_size)
		_posture_label.modulate = Color(0.7, 0.2, 1.0)
		_posture_label.position = Vector2(28.0, 16.0)
		add_child(_posture_label)

func _process(delta: float) -> void:
	_timer += delta

	## Subir flotando
	position.y -= FLOAT_SPEED * delta

	## Fade out en la segunda mitad de la vida
	var ratio: float = _timer / LIFETIME
	if ratio > 0.5:
		var alpha: float = 1.0 - ((ratio - 0.5) / 0.5)
		modulate.a = alpha

	if _timer >= LIFETIME:
		queue_free()

## Determina el color del daño a vida según porcentaje de vida máxima
func _get_life_color(damage: float, max_hp: float, is_heavy: bool) -> Color:
	if is_heavy:
		return Color(0.545, 0.0, 0.0)      # rojo oscuro — heavy hit

	if max_hp <= 0.0:
		return Color.WHITE

	var ratio: float = damage / max_hp
	if ratio >= 0.25:
		return Color(1.0, 0.125, 0.125)    # rojo brillante — crítico
	elif ratio >= 0.15:
		return Color(1.0, 0.549, 0.0)      # naranja — elevado
	elif ratio >= 0.05:
		return Color.WHITE                  # blanco — normal
	else:
		return Color(0.4, 0.4, 0.4)        # gris oscuro — bajo
