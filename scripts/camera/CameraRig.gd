extends Node
# scripts/camera/CameraRig.gd

func follow_x(cam: Camera3D, target_x: float, deadzone: float, smooth: float, delta: float) -> void:
	if cam == null:
		return
	var dx: float = target_x - cam.position.x
	if abs(dx) > deadzone:
		var tx: float = target_x - sign(dx) * deadzone
		var t: float = 1.0 - pow(0.001, delta * smooth)
		cam.position.x = lerp(cam.position.x, tx, t)
