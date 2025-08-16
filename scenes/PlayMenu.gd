extends Control

# Normaliza: minúsculas, sin acentos comunes (áéíóúüñ)
func _norm(s: String) -> String:
	var t: String = s.to_lower()
	t = t.replace("á","a").replace("é","e").replace("í","i").replace("ó","o").replace("ú","u").replace("ü","u").replace("ñ","n")
	return t.strip_edges()

func _ready() -> void:
	_autowire_buttons()
	# Popup con el resultado si existe
	if GameState and GameState.has_method("consume_result_message"):
		var _msg: String = GameState.consume_result_message()
		if _msg != "":
			var d: AcceptDialog = AcceptDialog.new()
			d.dialog_text = _msg
			add_child(d)
			d.popup_centered()

func _autowire_buttons() -> void:
	# Busca TODOS los botones en profundidad y conecta segun su texto
	var seen: Dictionary = {}
	var stack: Array[Node] = [self]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for c: Node in node.get_children():
			stack.push_back(c)
			if c is Button:
				var b: Button = c as Button
				if seen.has(b): continue
				seen[b] = true
				var label: String = _norm(b.text)
				if label == "":
					label = _norm(b.name)

				if label.find("jugar") != -1 or label.find("nueva") != -1 or label == "new" or label.find("start") != -1:
					b.pressed.connect(_on_new)
				elif label.find("continuar") != -1 or label.find("continue") != -1 or label.find("load") != -1:
					b.pressed.connect(_on_continue)
				elif label.find("configurar") != -1 or label.find("ajustes") != -1 or label.find("opciones") != -1 or label.find("settings") != -1 or label.find("options") != -1:
					b.pressed.connect(_on_settings)
				elif label.find("salir") != -1 or label.find("exit") != -1 or label.find("quit") != -1:
					b.pressed.connect(_on_quit)
				# Si no coincide nada, lo dejamos sin conectar

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
	# Si tienes un Settings.tscn, cámbialo aquí
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
