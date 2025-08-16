extends Control

@onready var btn_new: Button = get_node_or_null("VBox/NewGameButton") as Button
@onready var btn_continue: Button = get_node_or_null("VBox/ContinueButton") as Button
@onready var btn_back: Button = get_node_or_null("VBox/BackButton") as Button

func _ready() -> void:
	# Conectar botones por ruta EXACTA del .tscn
	if btn_new != null:
		btn_new.pressed.connect(_on_new)
	else:
		push_warning("No se encontró VBox/NewGameButton")
	if btn_continue != null:
		btn_continue.pressed.connect(_on_continue)
	else:
		push_warning("No se encontró VBox/ContinueButton")
	if btn_back != null:
		btn_back.pressed.connect(_on_back)
	else:
		push_warning("No se encontró VBox/BackButton")

	# Mostrar popup con mensaje de resultado si existe
	if GameState != null and GameState.has_method("consume_result_message"):
		var msg: String = GameState.consume_result_message()
		if msg != "":
			var d: AcceptDialog = AcceptDialog.new()
			d.dialog_text = msg
			add_child(d)
			d.popup_centered()

func _on_new() -> void:
	if GameState != null and GameState.has_method("new_game"):
		GameState.new_game()
	var scene_path: String = "res://scenes/GalaxyMap.tscn"
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_warning("No se encontró %s" % scene_path)

func _on_continue() -> void:
	if GameState != null and GameState.has_method("has_save") and GameState.has_save():
		if GameState.has_method("continue_game"):
			GameState.continue_game()
		var scene_path: String = "res://scenes/GalaxyMap.tscn"
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)
		else:
			push_warning("No se encontró %s" % scene_path)
	else:
		push_warning("No hay partida guardada")

func _on_back() -> void:
	var main_menu: String = "res://scenes/MainMenu.tscn"
	if ResourceLoader.exists(main_menu):
		get_tree().change_scene_to_file(main_menu)
	else:
		push_warning("No se encontró %s" % main_menu)
