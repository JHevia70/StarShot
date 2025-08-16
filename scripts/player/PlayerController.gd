extends Node
# scripts/player/PlayerController.gd

var _last_x: float = 0.0

func reset_last_x(x: float) -> void:
	_last_x = x

func move_lateral(player: Node3D, axis: float, speed: float, delta: float, half_width: float) -> void:
	if player == null:
		return
	if abs(axis) > 0.001:
		player.position.x = clamp(player.position.x + axis * speed * delta, -half_width, half_width)

func apply_bank(player: Node3D, move_speed: float, bank_max_deg: float, bank_speed: float, delta: float) -> void:
	if player == null:
		return
	var vx: float = (player.position.x - _last_x) / max(0.0001, delta)
	var target_bank: float = clamp(vx / max(0.001, move_speed), -1.0, 1.0) * bank_max_deg
	var current_deg: float = rad_to_deg(player.rotation.z)
	var t: float = 1.0 - pow(0.001, delta * bank_speed)
	var new_deg: float = lerp(current_deg, -target_bank, t)
	player.rotation.z = deg_to_rad(new_deg)
	_last_x = player.position.x
