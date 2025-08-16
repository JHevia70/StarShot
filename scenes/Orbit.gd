extends Node

@export var orbit_radius: float = 5.0
@export var orbit_speed: float = 0.22
var angle: float = 0.0

func _process(delta: float) -> void:
	angle += orbit_speed * delta
	var planet: Node3D = get_parent() as Node3D
	if planet == null:
		return
	var star: Node3D = planet.get_parent() as Node3D
	if star == null:
		return
	var x: float = cos(angle) * orbit_radius
	var z: float = sin(angle) * orbit_radius
	planet.position = Vector3(x, 0.0, z)
