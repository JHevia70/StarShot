extends Control

func _ready() -> void:
	var _msg := GameState.consume_result_message()
	if _msg != "":
		var d := AcceptDialog.new()
		d.dialog_text = _msg
		add_child(d)
		d.popup_centered()
	var btn := $Hangar if has_node("Hangar") else find_child("Hangar", true, false)
	if btn and btn is Button:
		(btn as Button).pressed.connect(_open_hangar)

func _open_hangar() -> void:
	var s := load("res://ui/Shop.tscn")
	if s:
		var inst = s.instantiate()
		get_tree().current_scene.add_child(inst)
	else:
		push_warning("No se encontró res://ui/Shop.tscn")
