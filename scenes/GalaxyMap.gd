extends Node3D

const TOTAL_PLANETS: int = 100
const MIN_PLANETS_PER_STAR: int = 5
const MAX_PLANETS_PER_STAR: int = 10
const STAR_TYPES: Array = [ "O", "B", "A", "F", "G", "K", "M" ]

@export var sky_path: String = "res://textures/nebula_panorama.hdr" # Equirectangular HDR/EXR/PNG

@onready var cam: Camera3D = $Camera3D as Camera3D
@onready var env: WorldEnvironment = $WorldEnvironment as WorldEnvironment
@onready var hangar_btn: Button = $HUD/HBox/Hangar as Button
@onready var label_info: Label = $HUD/HBox/Info as Label

var stars: Array = []                 # Array[Node3D]
var planets: Array = []               # Array[Node3D]
var star_planet_counts: Array = []    # Array[int]
var planet_to_unlock_index: int = 0   # índice global del siguiente planeta visible
var highest_unlocked: int = -1        # último planeta superado

# cámara orbital
var yaw: float = 0.0
var pitch: float = -0.28
var dist: float = 52.0
var rotate_sensitivity: float = 0.01
var zoom_step: float = 5.0
var dist_min: float = 18.0
var dist_max: float = 160.0
var target: Vector3 = Vector3.ZERO

func _ready() -> void:
	randomize()
	if cam != null:
		cam.current = true
	# Cielo: PanoramaSky si hay nebulosa, sino procedural
	var env_res: Environment = Environment.new()
	var sky_res: Sky = Sky.new()
	if sky_path != "" and ResourceLoader.exists(sky_path):
		var pano: PanoramaSkyMaterial = PanoramaSkyMaterial.new()
		var tex: Texture2D = load(sky_path) as Texture2D
		pano.panorama = tex
		sky_res.sky_material = pano
	else:
		var proc: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
		proc.sky_top_color = Color(0.01, 0.01, 0.03)
		proc.sky_horizon_color = Color(0.02, 0.02, 0.06)
		proc.ground_horizon_color = Color(0.01, 0.01, 0.02)
		sky_res.sky_material = proc
	env_res.background_mode = Environment.BG_SKY
	env_res.sky = sky_res
	if env != null:
		env.environment = env_res

	# Progreso (solo un planeta nuevo visible cada vez)
	highest_unlocked = -1
	if GameState != null and "highest_unlocked" in GameState:
		highest_unlocked = int(GameState.highest_unlocked)
	planet_to_unlock_index = max(0, highest_unlocked + 1)

	if hangar_btn != null:
		hangar_btn.pressed.connect(_on_hangar)

	_build_galaxy()
	_focus_last_unlocked_star()
	_update_camera()

func _build_galaxy() -> void:
	stars.clear()
	planets.clear()
	star_planet_counts.clear()

	# Reparto 5..10 planetas por estrella hasta total 100
	var remaining: int = TOTAL_PLANETS
	while remaining > 0:
		var chunk: int = MIN_PLANETS_PER_STAR + randi_range(0, MAX_PLANETS_PER_STAR - MIN_PLANETS_PER_STAR)
		if chunk > remaining:
			chunk = remaining
		star_planet_counts.append(chunk)
		remaining -= chunk

	# Estrellas dispersas con separación mínima
	var min_r: float = 22.0
	var max_r: float = 64.0
	var min_sep: float = 8.0
	var height_jitter: float = 6.5
	var star_positions: Array = []  # Array[Vector3]

	for i in range(star_planet_counts.size()):
		var pos: Vector3 = _pick_star_pos(star_positions, min_r, max_r, min_sep, height_jitter)
		star_positions.append(pos)
		var stype: String = STAR_TYPES[randi() % STAR_TYPES.size()]
		var star_node: Node3D = _spawn_star(pos, stype, i)
		add_child(star_node)
		stars.append(star_node)

		# Planetas de esta estrella
		var pcount: int = int(star_planet_counts[i])
		for p in range(pcount):
			var orbit_dist: float = 3.0 + 2.3 * float(p) + randf() * 0.6
			var planet: Node3D = _spawn_planet(star_node, orbit_dist, i, p)
			planets.append(planet)

	if label_info != null:
		label_info.text = "RMB: rotar | Rueda: zoom | Click planeta visible: transmisión"

func _pick_star_pos(existing: Array, min_r: float, max_r: float, min_sep: float, height_jitter: float) -> Vector3:
	var tries: int = 0
	while tries < 120:
		var r: float = lerp(min_r, max_r, randf())
		var ang: float = randf() * TAU
		var y: float = (randf() * 2.0 - 1.0) * height_jitter
		var cand: Vector3 = Vector3(cos(ang) * r, y, sin(ang) * r)
		var ok: bool = true
		for v in existing:
			if (v as Vector3).distance_to(cand) < min_sep:
				ok = false
				break
		if ok:
			return cand
		tries += 1
	return Vector3(randf() * max_r, 0.0, randf() * max_r)

func _focus_last_unlocked_star() -> void:
	var last_idx: int = max(0, highest_unlocked)  # si no hay progreso, 0
	var sidx: int = _star_of_global_index(last_idx)
	if sidx >= 0 and sidx < stars.size():
		target = (stars[sidx] as Node3D).global_position
		dist = 40.0
		yaw = 0.0
		pitch = -0.28

func _star_of_global_index(gidx: int) -> int:
	var acc: int = 0
	for i in range(star_planet_counts.size()):
		var next_acc: int = acc + int(star_planet_counts[i])
		if gidx >= acc and gidx < next_acc:
			return i
		acc = next_acc
	return clamp(star_planet_counts.size() - 1, 0, 9999)

func _spawn_star(pos: Vector3, stype: String, star_index: int) -> Node3D:
	var star: Node3D = Node3D.new()
	star.name = "Star_%d" % star_index
	star.position = pos

	var mesh: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.5
	sphere.height = 3.0
	sphere.radial_segments = 64
	sphere.rings = 32
	mesh.mesh = sphere

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var col: Color = _star_color(stype)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.0
	mesh.material_override = mat
	star.add_child(mesh)

	# Nombre
	var lbl: Label3D = Label3D.new()
	lbl.text = "Estrella %d (%s)" % [star_index + 1, stype]
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 2.0, 0)
	star.add_child(lbl)

	# Corona de partículas
	_add_corona(star, col)

	return star

func _add_corona(star: Node3D, col: Color) -> void:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.amount = 140
	particles.lifetime = 1.9
	particles.one_shot = false
	particles.emitting = true
	particles.local_coords = true

	var pm: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 1.3
	pm.gravity = Vector3.ZERO
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.25
	pm.angular_velocity_min = -0.4
	pm.angular_velocity_max = 0.4
	pm.scale_min = 0.8
	pm.scale_max = 1.3

	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([Color(col.r, col.g, col.b, 0.9), Color(col.r, col.g, col.b, 0.0)])
	var ramp: GradientTexture1D = GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp

	particles.process_material = pm
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.6, 0.6)
	particles.draw_pass_1 = quad

	star.add_child(particles)

func _spawn_planet(star_node: Node3D, orbit_radius: float, star_index: int, local_index: int) -> Node3D:
	var planet_root: Node3D = Node3D.new()
	planet_root.name = "Planet_%d_%d" % [star_index, local_index]
	star_node.add_child(planet_root)

	# render
	var mesh: MeshInstance3D = MeshInstance3D.new()
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

	# Rotación suave del planeta
	var spin_script: Script = load("res://scenes/Spin.gd") as Script
	if spin_script != null:
		var spin: Node = spin_script.new()
		spin.set("speed", 0.06) # lento
		planet_root.add_child(spin)

	# nombre flotante
	var lbl: Label3D = Label3D.new()
	lbl.text = "P%d-%d" % [star_index + 1, local_index + 1]
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, sphere.radius + 0.6, 0)
	planet_root.add_child(lbl)

	# órbita
	var orbit_script: Script = load("res://scenes/Orbit.gd") as Script
	if orbit_script != null:
		var orbit_node: Node = orbit_script.new()
		planet_root.add_child(orbit_node)
		orbit_node.set("orbit_radius", orbit_radius)
		orbit_node.set("orbit_speed", 0.20 + randf() * 0.25)

	# click
	var area: Area3D = Area3D.new()
	area.input_ray_pickable = true
	var colshape: CollisionShape3D = CollisionShape3D.new()
	var sph: SphereShape3D = SphereShape3D.new()
	sph.radius = sphere.radius * 1.25
	colshape.shape = sph
	area.add_child(colshape)
	planet_root.add_child(area)
	area.input_event.connect(_on_planet_input.bind(planet_root))

	# visibilidad: completed (<= highest_unlocked) + el siguiente (planet_to_unlock_index)
	var global_idx: int = planets.size()
	var unlocked: bool = (global_idx <= highest_unlocked) or (global_idx == planet_to_unlock_index)
	mesh.visible = unlocked
	lbl.visible = unlocked
	area.visible = unlocked
	planet_root.set_meta("global_index", global_idx)
	planet_root.set_meta("display_name", "Planeta %d-%d" % [star_index + 1, local_index + 1])
	return planet_root

func _on_planet_input(_camera: Node, event: InputEvent, _click_position: Vector3, _click_normal: Vector3, _shape_idx: int, planet: Node) -> void:
	if event is InputEventMouseButton:
		var ev: InputEventMouseButton = event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			var idx: int = int(planet.get_meta("global_index"))
			if idx <= highest_unlocked or idx == planet_to_unlock_index:
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
