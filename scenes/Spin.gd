extends Node

@export var speed: float = 0.06

func _process(delta: float) -> void:
	var body: Node3D = get_parent() as Node3D
	if body == null:
		return
	body.rotate_y(speed * delta)
