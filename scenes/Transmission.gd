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
	# Cargar y reproducir
	if ResourceLoader.exists(video_path):
		var stream: Resource = load(video_path)
		if stream != null and player != null:
			player.stream = stream
			player.autoplay = true
			player.stretch = true
			player.stretch_mode = VideoStreamPlayer.STRETCH_KEEP_ASPECT_COVER
			player.play()
	else:
		push_warning("No se encontró el video en %s. Convierte tu MP4 a WEBM y colócalo ahí." % video_path)

func _on_go() -> void:
	var shooter_path: String = "res://scenes/Shooter.tscn"
	if ResourceLoader.exists(shooter_path):
		get_tree().change_scene_to_file(shooter_path)
	else:
		push_warning("No se encontró Shooter.tscn")
