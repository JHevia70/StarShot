extends Control

func _ready() -> void:
	# Conectar botones aunque no estén enlazados en el .tscn
	var bnew := _find_button(["New", "NuevaPartida", "Nueva", "Start", "Jugar", "BTN_New"]) as Button
	var bcon := _find_button(["Continue", "Continuar", "Load", "BTN_Continue"]) as Button
	var bback := _find_button(["Back", "Volver", "Atras", "Atrás", "BTN_Back"]) as Button
	if bnew: bnew.pressed.connect(_on_new)
	if bcon: bcon.pressed.connect(_on_continue)
	if bback: bback.pressed.connect(_on_back)

	# Mostrar mensaje de resultado si lo hay
	if GameState and GameState.has_method("consume_result_message"):
		var _msg := GameState.consume_result_message()
		if _msg != "":
			var d := AcceptDialog.new()
			d.dialog_text = _msg
			add_child(d)
			d.popup_centered()

func _find_button(names: Array) -> Button:
	# 1) Buscar por nombre (búsqueda profunda)
	for nm in names:
		var n := find_child(nm, true, false)
		if n and n is Button:
			return n
	# 2) Buscar por texto del botón (búsqueda profunda)
	var stack: Array = [self]
	while stack.size() > 0:
		var node := stack.pop_back()
		for c in node.get_children():
			stack.push_back(c)
			if c is Button:
				var bt := c as Button
				for nm in names:
					if bt.text.to_lower() == String(nm).to_lower():
						return bt
	return null

func _on_new() -> void:
	if GameState and GameState.has_method("new_game"):
		GameState.new_game()
	var scene_path := "res://scenes/GalaxyMap.tscn"
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_warning("No se encontró %s" % scene_path)

func _on_continue() -> void:
	if GameState and GameState.has_method("has_save") and GameState.has_save():
		if GameState.has_method("continue_game"):
			GameState.continue_game()
		var scene_path := "res://scenes/GalaxyMap.tscn"
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)
		else:
			push_warning("No se encontró %s" % scene_path)
	else:
		push_warning("No hay partida guardada")

func _on_back() -> void:
	var main_menu := "res://scenes/MainMenu.tscn"
	if ResourceLoader.exists(main_menu):
		get_tree().change_scene_to_file(main_menu)
	else:
		push_warning("No se encontró %s" % main_menu)
