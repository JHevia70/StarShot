extends Node3D

const TOTAL_PLANETS: int = 100
const MIN_PLANETS_PER_STAR: int = 5
const MAX_PLANETS_PER_STAR: int = 10
const STAR_TYPES := [ "O", "B", "A", "F", "G", "K", "M" ]

@onready var cam: Camera3D = $Camera3D as Camera3D
@onready var env: WorldEnvironment = $WorldEnvironment as WorldEnvironment
@onready var hangar_btn: Button = $HUD/HBox/Hangar as Button
@onready var label_info: Label = $HUD/HBox/Info as Label

var stars: Array = []    # Array[Node3D]
var planets: Array = []  # Array[Node3D]
var planet_to_unlock_index: int = 0

# cámara orbital
var yaw: float = 0.0
var pitch: float = -0.2
var dist: float = 60.0
var rotate_sensitivity: float = 0.01
var zoom_step: float = 5.0
var dist_min: float = 20.0
var dist_max: float = 150.0
var target: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Activar cámara
	if cam != null:
		cam.current = true
	# Cielo procedural básico
	var env_res: Environment = Environment.new()
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.01, 0.01, 0.03)
	sky_mat.sky_horizon_color = Color(0.02, 0.02, 0.06)
	var sky_res: Sky = Sky.new()
	sky_res.sky_material = sky_mat
	env_res.background_mode = Environment.BG_SKY
	env_res.sky = sky_res
	if env != null:
		env.environment = env_res

	# Progreso de desbloqueo
	var highest: int = -1
	if GameState != null and "highest_unlocked" in GameState:
		highest = int(GameState.highest_unlocked)
	planet_to_unlock_index = max(0, highest + 1)

	if hangar_btn != null:
		hangar_btn.pressed.connect(_on_hangar)

	_build_galaxy()
	_update_camera()

func _build_galaxy() -> void:
	stars.clear()
	planets.clear()

	# Repartir 100 planetas en bloques de 5..10 por estrella
	var remaining: int = TOTAL_PLANETS
	var distribution: Array = []  # Array[int]
	while remaining > 0:
		var chunk: int = MIN_PLANETS_PER_STAR + randi_range(0, MAX_PLANETS_PER_STAR - MIN_PLANETS_PER_STAR)
		if chunk > remaining:
			chunk = remaining
		distribution.append(chunk)
		remaining -= chunk

	var ring_radius: float = 28.0
	var star_count: int = distribution.size()
	var i: int = 0
	while i < star_count:
		var ang: float = TAU * float(i) / float(max(1, star_count))
		var pos: Vector3 = Vector3(cos(ang) * ring_radius, 0.0, sin(ang) * ring_radius)
		var stype: String = STAR_TYPES[randi() % STAR_TYPES.size()]
		var star_node: Node3D = _spawn_star(pos, stype, i)
		add_child(star_node)
		stars.append(star_node)

		var pcount: int = int(distribution[i])
		var p: int = 0
		while p < pcount:
			var orbit_dist: float = 3.0 + 2.6 * float(p) + randf() * 0.6
			var planet: Node3D = _spawn_planet(star_node, orbit_dist, i, p)
			planets.append(planet)
			p += 1
		i += 1

	if label_info != null:
		label_info.text = "RMB: rotar | Rueda: zoom | Click planeta visible: transmisión"

func _spawn_star(pos: Vector3, stype: String, star_index: int) -> Node3D:
	var star: Node3D = Node3D.new()
	star.name = "Star_%d" % star_index
	star.position = pos

	var mesh: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.4
	sphere.height = 2.8
	sphere.radial_segments = 64
	sphere.rings = 32
	mesh.mesh = sphere
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.visible = true

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var col: Color = _star_color(stype)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.0
	mesh.material_override = mat

	star.add_child(mesh)

	var lbl: Label3D = Label3D.new()
	lbl.text = "Estrella %d (%s)" % [star_index + 1, stype]
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 2.0, 0)
	star.add_child(lbl)
	return star

func _spawn_planet(star_node: Node3D, orbit_radius: float, star_index: int, local_index: int) -> Node3D:
	var planet_root: Node3D = Node3D.new()
	planet_root.name = "Planet_%d_%d" % [star_index, local_index]
	star_node.add_child(planet_root)

	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.input_pickable = true
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.45 + 0.2 * randf()
	sphere.height = sphere.radius * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	mesh.mesh = sphere
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color.from_hsv(randf(), 0.55, 0.95)
	mesh.material_override = m
	planet_root.add_child(mesh)

	var lbl: Label3D = Label3D.new()
	lbl.text = "P%d-%d" % [star_index + 1, local_index + 1]
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, sphere.radius + 0.6, 0)
	planet_root.add_child(lbl)

	# Órbita
	var orbit_script: Script = load("res://scenes/Orbit.gd") as Script
	if orbit_script != null:
		var orbit_node: Node = orbit_script.new()
		planet_root.add_child(orbit_node)
		orbit_node.set("orbit_radius", orbit_radius)
		orbit_node.set("orbit_speed", 0.3 + randf() * 0.4)

	# Área clickable
	var area: Area3D = Area3D.new()
	area.input_ray_pickable = true
	var colshape: CollisionShape3D = CollisionShape3D.new()
	var sph: SphereShape3D = SphereShape3D.new()
	sph.radius = sphere.radius * 1.25
	colshape.shape = sph
	area.add_child(colshape)
	planet_root.add_child(area)
	area.input_event.connect(_on_planet_input.bind(planet_root))

	var global_idx: int = planets.size()
	var unlocked: bool = (global_idx <= planet_to_unlock_index)
	mesh.visible = unlocked
	lbl.visible = unlocked
	area.visible = unlocked
	planet_root.set_meta("global_index", global_idx)
	planet_root.set_meta("display_name", "Planeta %d-%d" % [star_index + 1, local_index + 1])
	return planet_root

func _on_planet_input(camera: Node, event: InputEvent, click_position: Vector3, click_normal: Vector3, shape_idx: int, planet: Node) -> void:
	if event is InputEventMouseButton:
		var ev: InputEventMouseButton = event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			var idx: int = int(planet.get_meta("global_index"))
			if idx <= planet_to_unlock_index:
				_select_planet(planet)

func _select_planet(planet: Node) -> void:
	var planet_name: String = str(planet.get_meta("display_name"))
	if GameState != null:
		if GameState.has_method("set_target"):
			GameState.set_target(planet_name)
		elif "player_stats" in GameState:
			GameState.player_stats["target"] = planet_name
	var scene_path: String = "res://scenes/Transmission.tscn"
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_warning("No se encontró Transmission.tscn")

func _star_color(stype: String) -> Color:
	match stype:
		"O":
			return Color(0.6, 0.7, 1.0)
		"B":
			return Color(0.5, 0.6, 1.0)
		"A":
			return Color(0.8, 0.85, 1.0)
		"F":
			return Color(1.0, 1.0, 0.9)
		"G":
			return Color(1.0, 0.95, 0.6)
		"K":
			return Color(1.0, 0.8, 0.5)
		"M":
			return Color(1.0, 0.6, 0.4)
		_:
			return Color(1,1,1)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		yaw -= mm.relative.x * rotate_sensitivity
		pitch -= mm.relative.y * rotate_sensitivity
		pitch = clamp(pitch, -1.2, 0.6)
		_update_camera()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			dist = max(dist_min, dist - zoom_step)
			_update_camera()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			dist = min(dist_max, dist + zoom_step)
			_update_camera()

func _update_camera() -> void:
	var rot: Basis = Basis()
	rot = rot.rotated(Vector3.UP, yaw)
	rot = rot.rotated(Vector3.RIGHT, pitch)
	var offset: Vector3 = rot * Vector3(0, 0, dist)
	cam.transform.origin = target + offset
	cam.look_at(target, Vector3.UP)

func _on_hangar() -> void:
	var shop_path: String = "res://ui/Shop.tscn"
	if ResourceLoader.exists(shop_path):
		var s: PackedScene = load(shop_path) as PackedScene
		if s != null:
			var inst: Node = s.instantiate()
			get_tree().current_scene.add_child(inst)
	else:
		push_warning("No se encontró res://ui/Shop.tscn")
