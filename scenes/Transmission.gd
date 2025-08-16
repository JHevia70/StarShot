extends Control

@export var video_path: String = "res://video/transmission.ogv"

@onready var player: VideoStreamPlayer = $Video as VideoStreamPlayer
@onready var title: Label = $Overlay/VBox/Title as Label
@onready var action: Button = $Overlay/VBox/Action as Button

func _ready() -> void:
	var planet_name: String = "planeta desconocido"
	if GameState != null:
		if "player_stats" in GameState and "target" in GameState.player_stats:
			planet_name = str(GameState.player_stats["target"])
		elif GameState.has_method("get_target"):
			planet_name = str(GameState.get_target())
	title.text = "Transmisión desde %s" % planet_name

	if action != null:
		action.pressed.connect(_on_go)

	# Asegurar que ocupa toda la pantalla
	if player != null:
		player.expand = true
		# Loop manual por si el stream no soporta 'loop'
		if not player.finished.is_connected(_on_finished):
			player.finished.connect(_on_finished)

	var path_use: String = _resolve_video_path(video_path)
	if path_use == "":
		var msg: String = "No se encontró ningún OGV en res://video/."
		var d: AcceptDialog = AcceptDialog.new()
		d.dialog_text = msg
		add_child(d)
		d.popup_centered()
		push_warning(msg)
		return

	var stream_res: Resource = load(path_use)
	if stream_res != null and player != null:
		player.stream = stream_res
		player.play()
		print("[Transmission] Reproduciendo: ", path_use)
	else:
		push_warning("No se pudo cargar el video: %s" % path_use)

func _on_finished() -> void:
	# Reiniciar para crear bucle
	if player != null:
		player.play()

func _resolve_video_path(pref: String) -> String:
	if pref != "" and ResourceLoader.exists(pref):
		return pref
	var folder: String = "res://video"
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var best: String = ""
	var name: String = dir.get_next()
	while name != "":
		if not dir.current_is_dir():
			var low: String = name.to_lower()
			if low.ends_with(".ogv") or low.ends_with(".ogx") or low.ends_with(".ogm"):
				var full: String = folder + "/" + name
				if low.begins_with("transmission") or low.begins_with("transmision"):
					dir.list_dir_end()
					return full
				elif best == "":
					best = full
		name = dir.get_next()
	dir.list_dir_end()
	return best

func _on_go() -> void:
	var shooter_path: String = "res://scenes/Shooter.tscn"
	if ResourceLoader.exists(shooter_path):
		get_tree().change_scene_to_file(shooter_path)
	else:
		push_warning("No se encontró Shooter.tscn")
