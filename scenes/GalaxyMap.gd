extends Node3D

const TOTAL_PLANETS: int = 100
const MIN_PLANETS_PER_STAR: int = 5
const MAX_PLANETS_PER_STAR: int = 10
const STAR_TYPES: Array = ["O","B","A","F","G","K","M"]

@export var sky_path: String = "res://textures/nebula_panorama.hdr"

@onready var cam: Camera3D = $Camera3D if has_node("Camera3D") else Camera3D.new()
@onready var env_node: WorldEnvironment = $WorldEnvironment if has_node("WorldEnvironment") else WorldEnvironment.new()
@onready var sun: DirectionalLight3D = $SunLight if has_node("SunLight") else DirectionalLight3D.new()
@onready var hangar_btn: Button = $HUD/HBox/Hangar if has_node("HUD/HBox/Hangar") else null
@onready var info_label: Label = $HUD/HBox/Info if has_node("HUD/HBox/Info") else null

var stars: Array = []               # Array[Node3D]
var planets: Array = []             # Array[Node3D]
var star_planet_counts: Array = []  # Array[int]
var highest_unlocked: int = -1
var next_visible: int = 0

# cámara orbital
var yaw: float = 0.0
var pitch: float = -0.28
var dist: float = 50.0
var dist_min: float = 18.0
var dist_max: float = 160.0
var rotate_sensitivity: float = 0.01
var zoom_step: float = 5.0
var target: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Garantizar cámara, env y luz
	if not has_node("Camera3D"):
		cam.name = "Camera3D"
		add_child(cam)
	cam.current = true
	if not has_node("WorldEnvironment"):
		env_node.name = "WorldEnvironment"
		add_child(env_node)
	if not has_node("SunLight"):
		sun.name = "SunLight"
		add_child(sun)
	sun.light_energy = 1.2

	# Cielo
	var env_res: Environment = Environment.new()
	var sky: Sky = Sky.new()
	if sky_path != "" and ResourceLoader.exists(sky_path):
		var pano: PanoramaSkyMaterial = PanoramaSkyMaterial.new()
		var tex: Texture2D = load(sky_path) as Texture2D
		pano.panorama = tex
		sky.sky_material = pano
	else:
		var proc: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
		proc.sky_top_color = Color(0.01, 0.01, 0.03)
		proc.sky_horizon_color = Color(0.02, 0.02, 0.06)
		proc.ground_horizon_color = Color(0.01, 0.01, 0.02)
		sky.sky_material = proc
	env_res.background_mode = Environment.BG_SKY
	env_res.sky = sky
	env_node.environment = env_res

	# Progreso: SOLO 1 planeta visible al inicio
	highest_unlocked = -1
	if typeof(GameState) != TYPE_NIL and "highest_unlocked" in GameState:
		highest_unlocked = int(GameState.highest_unlocked)
	next_visible = max(0, highest_unlocked + 1)

	# HUD
	if hangar_btn != null:
		hangar_btn.pressed.connect(_on_hangar)
	if info_label != null:
		info_label.text = "RMB: rotar | Rueda: zoom | Click planeta visible: transmisión"

	_build_galaxy()
	_focus_on_last_star()
	_update_camera()

func _build_galaxy() -> void:
	stars.clear()
	planets.clear()
	star_planet_counts.clear()
	# Reparto por estrella
	var remaining: int = TOTAL_PLANETS
	while remaining > 0:
		var chunk: int = MIN_PLANETS_PER_STAR + randi_range(0, MAX_PLANETS_PER_STAR - MIN_PLANETS_PER_STAR)
		if chunk > remaining:
			chunk = remaining
		star_planet_counts.append(chunk)
		remaining -= chunk

	# Estrellas dispersas
	var min_r: float = 22.0
	var max_r: float = 64.0
	var min_sep: float = 8.0
	var height_jitter: float = 6.0
	var star_positions: Array = []  # Array[Vector3]
	for i in range(star_planet_counts.size()):
		var pos: Vector3 = _pick_star_pos(star_positions, min_r, max_r, min_sep, height_jitter)
		star_positions.append(pos)
		var stype: String = STAR_TYPES[randi() % STAR_TYPES.size()]
		var s: Node3D = _spawn_star(pos, stype, i)
		add_child(s)
		stars.append(s)
		var pcount: int = int(star_planet_counts[i])
		for p in range(pcount):
			var orbit_dist: float = 3.0 + 2.3 * float(p) + randf() * 0.6
			var planet: Node3D = _spawn_planet(s, orbit_dist, i, p)
			planets.append(planet)

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

func _focus_on_last_star() -> void:
	var last_idx: int = max(0, highest_unlocked)
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

func _spawn_star(pos: Vector3, stype: String, idx: int) -> Node3D:
	var n: Node3D = Node3D.new()
	n.name = "Star_%d" % idx
	n.position = pos
	var mi: MeshInstance3D = MeshInstance3D.new()
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = 1.5
	sm.height = 3.0
	sm.radial_segments = 64
	sm.rings = 32
	mi.mesh = sm
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var col: Color = _star_color(stype)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.0
	mi.material_override = mat
	n.add_child(mi)
	# Nombre
	var lbl: Label3D = Label3D.new()
	lbl.text = "Estrella %d (%s)" % [idx + 1, stype]
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 2.0, 0)
	n.add_child(lbl)
	# Corona
	_add_corona(n, col)
	return n

func _add_corona(star: Node3D, col: Color) -> void:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.amount = 140
	particles.lifetime = 1.8
	particles.emitting = true
	particles.local_coords = true
	var pm: ParticleProcessMaterial = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 1.3
	pm.gravity = Vector3.ZERO
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.25
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
	var p: Node3D = Node3D.new()
	p.name = "Planet_%d_%d" % [star_index, local_index]
	star_node.add_child(p)
	# render
	var mi: MeshInstance3D = MeshInstance3D.new()
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = 0.45 + 0.2 * randf()
	sm.height = sm.radius * 2.0
	sm.radial_segments = 32
	sm.rings = 16
	mi.mesh = sm
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color.from_hsv(randf(), 0.55, 0.95)
	mi.material_override = m
	p.add_child(mi)
	# spin
	var spin_s: Script = load("res://scenes/Spin.gd") as Script
	if spin_s != null:
		var spin: Node = spin_s.new()
		spin.set("speed", 0.06)
		p.add_child(spin)
	# label
	var lbl: Label3D = Label3D.new()
	lbl.text = "P%d-%d" % [star_index + 1, local_index + 1]
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, sm.radius + 0.6, 0)
	p.add_child(lbl)
	# órbita
	var orbit_s: Script = load("res://scenes/Orbit.gd") as Script
	if orbit_s != null:
		var orbit: Node = orbit_s.new()
		p.add_child(orbit)
		orbit.set("orbit_radius", orbit_radius)
		orbit.set("orbit_speed", 0.22 + randf() * 0.22)
	# click
	var area: Area3D = Area3D.new()
	area.input_ray_pickable = true
	var colshape: CollisionShape3D = CollisionShape3D.new()
	var sph: SphereShape3D = SphereShape3D.new()
	sph.radius = sm.radius * 1.25
	colshape.shape = sph
	area.add_child(colshape)
	p.add_child(area)
	area.input_event.connect(_on_planet_input.bind(p))
	# visibilidad: SOLO ganados (<= highest_unlocked) + EXACTO siguiente (== next_visible)
	var gidx: int = planets.size()
	var is_unlocked: bool = (gidx <= highest_unlocked)
	var is_next: bool = (gidx == next_visible)
	var unlocked: bool = is_unlocked or is_next
	mi.visible = unlocked
	lbl.visible = unlocked
	area.visible = unlocked
	p.set_meta("global_index", gidx)
	p.set_meta("display_name", "Planeta %d-%d" % [star_index + 1, local_index + 1])
	return p

func _on_planet_input(_camera: Node, event: InputEvent, _click_position: Vector3, _click_normal: Vector3, _shape_idx: int, planet: Node) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var idx: int = int(planet.get_meta("global_index"))
			if idx <= highest_unlocked or idx == next_visible:
				_select_planet(planet)

func _select_planet(planet: Node) -> void:
	var planet_name: String = str(planet.get_meta("display_name"))
	if typeof(GameState) != TYPE_NIL:
		if GameState.has_method("set_target"):
			GameState.set_target(planet_name)
		elif "player_stats" in GameState:
			GameState.player_stats["target"] = planet_name
	if ResourceLoader.exists("res://scenes/Transmission.tscn"):
		get_tree().change_scene_to_file("res://scenes/Transmission.tscn")
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
