extends Node

var data := {}

func _ready():
	var file := FileAccess.open("res://data/catalogo_datos.json", FileAccess.READ)
	if file == null:
		push_error("No se pudo cargar catalogo_datos.json")
		return

	var text := file.get_as_text()
	data = JSON.parse_string(text)

	if data == null:
		push_error("JSON inválido en catalogo_datos.json")
	else:
		print(" Catálogo de datos cargado correctamente")
