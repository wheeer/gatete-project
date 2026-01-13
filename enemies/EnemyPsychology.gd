extends Resource
class_name EnemyPsychology

enum Personality {
	MIEDOSO,
	VALEROSO,
	ASTUTO,
	VENGATIVO,
	OBSTINADO,
	NERVIOSO
}

@export var personality: Personality = Personality.MIEDOSO

# --- VALORES BASE (NO lógica) ---
@export var base_temple: float = 0.0
@export var panic_threshold: float = -50.0
@export var desperation_threshold: float = 30.0
@export var predict_skill: float = 0.0


func configure_from_personality() -> void:
	match personality:
		Personality.MIEDOSO:
			base_temple = -30
			panic_threshold = -40
			desperation_threshold = 10
			predict_skill = 0.1

		Personality.VALEROSO:
			base_temple = 30
			panic_threshold = -80
			desperation_threshold = 40
			predict_skill = 0.4

		Personality.ASTUTO:
			base_temple = 0
			panic_threshold = -50
			desperation_threshold = 30
			predict_skill = 0.7

		Personality.VENGATIVO:
			base_temple = 10
			panic_threshold = -60
			desperation_threshold = 60
			predict_skill = 0.5

		Personality.OBSTINADO:
			base_temple = 40
			panic_threshold = -100
			desperation_threshold = 80
			predict_skill = 0.2

		Personality.NERVIOSO:
			base_temple = -10
			panic_threshold = -30
			desperation_threshold = 20
			predict_skill = 0.3
