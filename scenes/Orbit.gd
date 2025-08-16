extends Node

@export var orbit_radius: float = 5.0
@export var orbit_speed: float = 0.5
var angle: float = 0.0

func _process(delta: float) -> void:
	angle += orbit_speed * delta
	var parent: Node3D = get_parent() as Node3D
	if parent == null:
		return
	var center: Node3D = parent.get_parent() as Node3D
	if center == null:
		return
	var x: float = cos(angle) * orbit_radius
	var z: float = sin(angle) * orbit_radius
	parent.translation = Vector3(x, 0.0, z)
