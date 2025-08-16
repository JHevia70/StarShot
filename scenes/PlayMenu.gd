extends Control

# Normaliza: minúsculas y sin acentos para matching robusto
func _norm(s: String) -> String:
	var t: String = s.strip_edges().to_lower()
	t = t.replace("á","a").replace("é","e").replace("í","i").replace("ó","o").replace("ú","u").replace("ü","u").replace("ñ","n")
	return t

func _ready() -> void:
	_autowire_buttons()
	# Popup con resultado si existe
	if GameState and GameState.has_method("consume_result_message"):
		var _msg: String = GameState.consume_result_message()
		if _msg != "":
			var d: AcceptDialog = AcceptDialog.new()
			d.dialog_text = _msg
			add_child(d)
			d.popup_centered()

func _autowire_buttons() -> void:
	var found: Array[String] = []
	var stack: Array[Node] = [self]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for c: Node in node.get_children():
			stack.push_back(c)
			if c is BaseButton:
				var b: BaseButton = c as BaseButton
				var label_raw: String = ""
				if b is Button:
					label_raw = (b as Button).text
				if label_raw == "":
					label_raw = b.name
				var key: String = _norm(label_raw)
				found.push_back("%s (%s)" % [label_raw, b.get_path()])
				# Conecta por patrones amplios
				if key.find("jugar") != -1 or key.find("nueva") != -1 or key == "new" or key.find("start") != -1 or key == "play":
					if not b.pressed.is_connected(_on_new):
						b.pressed.connect(_on_new)
				elif key.find("continuar") != -1 or key.find("continue") != -1 or key.find("load") != -1 or key.find("seguir") != -1:
					if not b.pressed.is_connected(_on_continue):
						b.pressed.connect(_on_continue)
				elif key.find("config") != -1 or key.find("ajustes") != -1 or key.find("opciones") != -1 or key.find("settings") != -1 or key.find("options") != -1:
					if not b.pressed.is_connected(_on_settings):
						b.pressed.connect(_on_settings)
				elif key.find("salir") != -1 or key.find("exit") != -1 or key.find("quit") != -1:
					if not b.pressed.is_connected(_on_quit):
						b.pressed.connect(_on_quit)
	# Log de diagnóstico
	print_rich("[b][PlayMenu][/b] Botones detectados:")
	for s: String in found:
		print_rich("  - %s" % s)

func _on_new() -> void:
	if GameState and GameState.has_method("new_game"):
		GameState.new_game()
	var scene_path: String = "res://scenes/GalaxyMap.tscn"
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_warning("No se encontró %s" % scene_path)

func _on_continue() -> void:
	if GameState and GameState.has_method("has_save") and GameState.has_save():
		if GameState.has_method("continue_game"):
			GameState.continue_game()
		var scene_path: String = "res://scenes/GalaxyMap.tscn"
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)
		else:
			push_warning("No se encontró %s" % scene_path)
	else:
		push_warning("No hay partida guardada")

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
