extends Control

@onready var btn_play: Button = get_node_or_null("VBox/PlayButton") as Button
@onready var btn_settings: Button = get_node_or_null("VBox/SettingsButton") as Button
@onready var btn_quit: Button = get_node_or_null("VBox/QuitButton") as Button

func _ready() -> void:
	# Conectar por rutas EXACTAS del .tscn
	if btn_play != null:
		btn_play.pressed.connect(_on_play)
	else:
		push_warning("No se encontró VBox/PlayButton")
	if btn_settings != null:
		btn_settings.pressed.connect(_on_settings)
	else:
		push_warning("No se encontró VBox/SettingsButton")
	if btn_quit != null:
		btn_quit.pressed.connect(_on_quit)
	else:
		push_warning("No se encontró VBox/QuitButton")

func _on_play() -> void:
	# Preferimos abrir PlayMenu si existe; si no, ir directo a GalaxyMap
	var playmenu_path: String = "res://scenes/PlayMenu.tscn"
	var galaxy_path: String = "res://scenes/GalaxyMap.tscn"
	if ResourceLoader.exists(playmenu_path):
		get_tree().change_scene_to_file(playmenu_path)
	elif ResourceLoader.exists(galaxy_path):
		get_tree().change_scene_to_file(galaxy_path)
	else:
		push_warning("No se encontró PlayMenu.tscn ni GalaxyMap.tscn")

func _on_settings() -> void:
	var settings_scene: String = "res://scenes/Settings.tscn"
	if ResourceLoader.exists(settings_scene):
		get_tree().change_scene_to_file(settings_scene)
	else:
		var d: AcceptDialog = AcceptDialog.new()
		d.dialog_text = "Configuración aún no disponible."
		add_child(d)
		d.popup_centered()

func _on_quit() -> void:
	get_tree().quit()
