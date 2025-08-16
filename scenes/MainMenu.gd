extends Control

func _ready() -> void:
    $VBox/PlayButton.pressed.connect(_on_play)
    $VBox/SettingsButton.pressed.connect(_on_settings)
    $VBox/QuitButton.pressed.connect(_on_quit)

func _on_play() -> void:
    get_tree().change_scene_to_file("res://scenes/PlayMenu.tscn")

func _on_settings() -> void:
    pass

func _on_quit() -> void:
    get_tree().quit()
