extends Node3D

@onready var cam: Camera3D = $Camera3D if has_node("Camera3D") else null
@onready var env: WorldEnvironment = $WorldEnvironment if has_node("WorldEnvironment") else null

func _ready() -> void:
	# Cámara segura y current
	if cam == null:
		cam = Camera3D.new()
		cam.name = "Camera3D"
		add_child(cam)
	cam.current = true
	await get_tree().process_frame
	cam.make_current()
	# Entorno con cielo procedural básico si no existe
	if env == null:
		env = WorldEnvironment.new()
		env.name = "WorldEnvironment"
		add_child(env)
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var proc := ProceduralSkyMaterial.new()
	proc.sky_top_color = Color(0.01,0.01,0.03)
	proc.sky_horizon_color = Color(0.02,0.02,0.06)
	sky.sky_material = proc
	e.sky = sky
	env.environment = e
	# Si tu script original genera estrellas/planetas en _ready, colócalo debajo de este bloque
	# o conserva tu GalaxyMap.gd completo; este archivo es sólo para evitar pantalla negra si faltaba cámara/entorno.
