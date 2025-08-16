Param(
    [string]$FilePath = "scenes/Shooter.gd"
)

try {
    if (!(Test-Path $FilePath)) {
        Write-Error "No se encontró $FilePath. Ejecuta este script desde la raíz del repo o pasa -FilePath."
        exit 1
    }

    $text = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8

    # 1º intento: función hasta antes de la siguiente 'func ' (al inicio de línea)
    $regex = [regex]'(?ms)^[\t ]*func\s+_physics_process\([^)]*\)\s*->\s*void\s*:\s*.*?(?=^\s*func\s+)'
    if (-not $regex.IsMatch($text)) {
        # 2º intento: función hasta el final del archivo
        $regex = [regex]'(?ms)^[\t ]*func\s+_physics_process\([^)]*\)\s*->\s*void\s*:\s*.*\z'
        if (-not $regex.IsMatch($text)) {
            Write-Error "No pude localizar la función 'func _physics_process(...)' en $FilePath."
            exit 2
        }
    }

    $newFn = @'
func _physics_process(delta: float) -> void:
	# Safety
	if player == null or cam == null:
		return

	# -------- Movimiento lateral (teclado/gamepad/táctil) --------
	var axis_kb: float = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var axis: float = axis_kb

	# Aplica movimiento (clamp a límites)
	if absf(axis) > 0.0:
		player.position.x = clamp(player.position.x + axis * move_speed * delta, -arena_half_width, arena_half_width)

	# -------- Cámara con deadzone (no recentra duro) --------
	var off: float = player.position.x - cam.position.x
	if absf(off) > cam_deadzone:
		var dz: float = cam_deadzone
		var target_x: float = player.position.x - signf(off) * dz
		var t: float = 1.0 - pow(0.001, delta * cam_smooth)
		cam.position.x = lerpf(cam.position.x, target_x, t)

	# -------- Inclinación (bank) según velocidad lateral --------
	var vx: float = (player.position.x - _last_player_x) / max(0.0001, delta)
	var target_bank: float = clamp(vx / move_speed, -1.0, 1.0) * bank_max_deg
	var current_deg: float = rad_to_deg(player.rotation.z)
	var k: float = 1.0 - pow(0.001, delta * bank_speed)
	var new_deg: float = lerpf(current_deg, -target_bank, k) # derecha = "baja" ala derecha
	player.rotation.z = deg_to_rad(new_deg)
	_last_player_x = player.position.x
'@

    $newText = $regex.Replace($text, $newFn, 1)
    Set-Content -LiteralPath $FilePath -Value $newText -Encoding UTF8
    Write-Host "OK: _physics_process() reemplazado en $FilePath"
    exit 0
}
catch {
    Write-Error $_
    exit 99
}
