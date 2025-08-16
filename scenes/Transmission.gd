extends Control

@export var video_path: String = "res://video/transmission.webm"

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

	# Ajustes de escalado (Godot 4): usa KEEP_ASPECT y expande al contenedor
	if player != null:
		player.expand = true
		player.stretch_mode = VideoStreamPlayer.STRETCH_KEEP_ASPECT  # 'COVER' no existe en VideoStreamPlayer

	# Cargar y reproducir (usa WEBM/OGV en Godot 4)
	if ResourceLoader.exists(video_path) and player != null:
		var stream_res: Resource = load(video_path)
		if stream_res != null and stream_res is VideoStream:
			player.stream = stream_res as VideoStream
			player.play()
	else:
		push_warning("No se encontró el video en: %s" % video_path)

func _on_go() -> void:
	var shooter_path: String = "res://scenes/Shooter.tscn"
	if ResourceLoader.exists(shooter_path):
		get_tree().change_scene_to_file(shooter_path)
	else:
		push_warning("No se encontró Shooter.tscn")
