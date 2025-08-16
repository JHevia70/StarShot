extends Node3D
const ENEMY_SCENES: Array[String] = [
	"res://models/enemies/EnemyWasp.tscn",
	"res://models/enemies/EnemyManta.tscn",
	"res://models/enemies/EnemyLeech.tscn",
]

const WORLD_X_LIMIT: float = 6.5
const PLANET_POS: Vector3 = Vector3(0, -27.33, -78.67)
const PLANET_RADIUS: float = 150.0
const PLANET_SPIN_X_DPS: float = 0.0
const ENEMY_LANES: Array = [-6.0, -3.0, 0.0, 3.0, 6.0]
const ENEMY_BASE_Z: float = -35.67

const CAM_DEADZONE_X: float = 0.6
const CAM_SMOOTH: float = 12.0
const CAM_EDGE_PAD: float = 1.2
const KEY_MOVE_SPEED_X: float = 10.0

var world: Node3D
var cam: Camera3D

var hud_layer: CanvasLayer
var hud_score_label: Label
var hud_hp_label: Label
var hud_hp_bar: ProgressBar

var score: int = 0
var target: int = 0
var enemies: Array = []
var bullets: Array = []
var loot: Array = []

var _shoot_timer: float = 0.0
var wave_timer: float = 0.0
var wave_cooldown: float = 3.0
var waves_done: int = 0
var boss_alive: bool = false

var player: Node3D
var touch_id: int = -1
var touch_active: bool = false
var mouse_dragging: bool = false

var planet_pivot: Node3D
var planet_node: MeshInstance3D
var atmo_node: MeshInstance3D

var shake_t: float = 0.0
var shake_amp: float = 0.0
var shake_rng := RandomNumberGenerator.new()

var cam_x: float = 0.0

func _ready() -> void:
	shake_rng.randomize()
	_ensure_scene_nodes()
	_ensure_starfield()
	_spawn_planet()

	var res := load("res://models/PlayerShip.tscn")
	if res != null and res is PackedScene:
		player = (res as PackedScene).instantiate()
	else:
		var fallback := MeshInstance3D.new()
		fallback.mesh = BoxMesh.new()
		fallback.material_override = _mat_unshaded(Color(0.9,0.9,1.0))
		player = fallback

	player.name = "Player"
	player.position = Vector3(0,0,5)
	world.add_child(player)

	target = GameState.required_score_for(GameState.current_planet)
	_setup_hud()
	_update_hud()

	if not GameState.has_save():
		GameState.player_stats["fire_rate"] = 2.0

	set_process_input(true)

func _ensure_scene_nodes() -> void:
	world = get_node_or_null("World")
	if world == null:
		world = Node3D.new()
		world.name = "World"
		add_child(world)

	cam = get_node_or_null("Cam")
	if cam == null:
		cam = Camera3D.new()
		cam.name = "Cam"
		add_child(cam)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 70.0
	cam.near = 0.05
	cam.far = 2000.0
	cam.position = Vector3(0, 7.67, 8.0)
	cam.look_at_from_position(cam.position, Vector3(0,0,-1.33), Vector3.UP)
	cam.current = true

	if get_node_or_null("Sun") == null:
		var sun := DirectionalLight3D.new()
		sun.name = "Sun"
		sun.light_energy = 1.8
		sun.shadow_enabled = true
		sun.directional_shadow_max_distance = 800.0
		sun.rotation_degrees = Vector3(-35, 35, 0)
		add_child(sun)

	if get_node_or_null("Env") == null:
		var we := WorldEnvironment.new()
		we.name = "Env"
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0,0,0)
		env.ambient_light_color = Color(0.03, 0.05, 0.08)
		env.ambient_light_energy = 0.08
		we.environment = env
		add_child(we)

func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	add_child(hud_layer)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	hud_layer.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(520, 0)
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	hud_score_label = Label.new()
	hud_score_label.text = "Score: 0"
	vbox.add_child(hud_score_label)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	vbox.add_child(hb)

	hud_hp_label = Label.new()
	hud_hp_label.text = "HP:"
	hb.add_child(hud_hp_label)

	hud_hp_bar = ProgressBar.new()
	hud_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_hp_bar.min_value = 0
	hud_hp_bar.max_value = 100
	hud_hp_bar.value = float(GameState.player_stats["health"])
	hb.add_child(hud_hp_bar)

func _update_hud() -> void:
	hud_score_label.text = "Score: %d / %d" % [score, target]
	hud_hp_bar.value = float(GameState.player_stats["health"])

var paths: Array[String] = ENEMY_SCENES
func _spawn_planet() -> void:
	planet_pivot = Node3D.new()
	planet_pivot.name = "PlanetPivot"
	planet_pivot.position = PLANET_POS
	add_child(planet_pivot)

	planet_node = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radial_segments = 128
	sphere.rings = 64
	sphere.radius = PLANET_RADIUS
	planet_node.mesh = sphere
	planet_node.position = Vector3.ZERO

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.albedo_color = Color(0.10,0.12,0.20)
	mat.metallic = 0.0
	mat.roughness = 0.75
	planet_node.material_override = mat
	planet_pivot.add_child(planet_node)

	atmo_node = MeshInstance3D.new()
	var halo := SphereMesh.new()
	halo.radial_segments = 64
	halo.rings = 32
	halo.radius = PLANET_RADIUS * 1.04
	atmo_node.mesh = halo
	atmo_node.position = Vector3.ZERO

	var amat := StandardMaterial3D.new()
	amat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	amat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	amat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	amat.albedo_color = Color(0.2,0.6,1.0, 0.04)
	amat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	amat.cull_mode = BaseMaterial3D.CULL_DISABLED
	atmo_node.material_override = amat
	planet_pivot.add_child(atmo_node)

func _ensure_starfield() -> void:
	if get_node_or_null("Stars") != null:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true

	var quad := QuadMesh.new()
	quad.size = Vector2(0.15, 0.15)
	mm.mesh = quad
	mm.instance_count = 1200

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1,1,1)

	var stars := MultiMeshInstance3D.new()
	stars.name = "Stars"
	stars.multimesh = mm
	stars.material_override = mat
	stars.extra_cull_margin = 200.0
	mm.custom_aabb = AABB(Vector3(-40,-120,-320), Vector3(80, 240, 220))
	add_child(stars)

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(mm.instance_count):
		var x := rng.randf_range(-30.0, 30.0)
		var y := rng.randf_range(-90.0, 90.0)
		var z := rng.randf_range(-260.0, -140.0)
		var s := rng.randf_range(0.6, 1.6)
		var bx := Basis.IDENTITY.scaled(Vector3(s, s, s))
		var t3d := Transform3D(bx, Vector3(x, y, z))
		mm.set_instance_transform(i, t3d)
		mm.set_instance_color(i, Color(1,1,1, rng.randf_range(0.6, 1.0)))

func _process(delta: float) -> void:
	if PLANET_SPIN_X_DPS != 0.0 and is_instance_valid(planet_pivot):
		var ang: float = deg_to_rad(PLANET_SPIN_X_DPS) * delta
		planet_pivot.rotate_object_local(Vector3.RIGHT, ang)

func _physics_process(delta: float) -> void:
	wave_timer -= delta
	if wave_timer <= 0.0 and not boss_alive:
		_spawn_wave()
		waves_done += 1
		if waves_done % 5 == 0:
			_spawn_boss()
		wave_timer = wave_cooldown

	var rate: float = max(0.5, float(GameState.player_stats["fire_rate"]))
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot()
		_shoot_timer = 1.0 / rate

	if not touch_active and not mouse_dragging:
		var axis := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		if axis != 0.0:
			player.position.x = clamp(player.position.x + axis * KEY_MOVE_SPEED_X * delta, -WORLD_X_LIMIT, WORLD_X_LIMIT)

	var left_bound := cam_x - CAM_DEADZONE_X
	var right_bound := cam_x + CAM_DEADZONE_X
	if player.position.x < left_bound:
		cam_x = lerp(cam_x, player.position.x + CAM_DEADZONE_X, CAM_SMOOTH * delta)
	elif player.position.x > right_bound:
		cam_x = lerp(cam_x, player.position.x - CAM_DEADZONE_X, CAM_SMOOTH * delta)

	cam_x = clamp(cam_x, -WORLD_X_LIMIT + CAM_EDGE_PAD, WORLD_X_LIMIT - CAM_EDGE_PAD)
	var cam_pos := Vector3(cam_x, 7.67, 8.0)
	var tgt := Vector3(cam_x, 0, -1.33)
	cam.look_at_from_position(cam_pos, tgt, Vector3.UP)

	_tick_bullets(delta)
	_tick_enemies(delta)
	_tick_loot(delta)
	_update_hud()

	if score >= target and enemies.size() == 0 and not boss_alive:
		GameState.complete_planet(GameState.current_planet, score)
		GameState.register_result(true, score, target)
		get_tree().change_scene_to_file("res://scenes/GalaxyMap.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			touch_active = true
			_touch_move(event.position)
		elif not event.pressed and event.index == touch_id:
			touch_active = false
			touch_id = -1
	elif event is InputEventScreenDrag:
		if touch_active and event.index == touch_id:
			_touch_move(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				mouse_dragging = true
				_touch_move(event.position)
			else:
				mouse_dragging = false
	elif event is InputEventMouseMotion:
		if mouse_dragging:
			_touch_move(event.position)

func _touch_move(pos: Vector2) -> void:
	var vx: float = float(get_viewport().get_visible_rect().size.x)
	if vx <= 0.0: return
	var t := (pos.x / vx) * 2.0 - 1.0
	player.position.x = clamp(t * WORLD_X_LIMIT, -WORLD_X_LIMIT, WORLD_X_LIMIT)

func _spawn_wave() -> void:
	var count: int = clamp(2 + int(GameState.current_planet * 0.2), 2, 8)
	for i in range(count):
		if randf() < 0.75:
			var lane_x: float = ENEMY_LANES[randi() % ENEMY_LANES.size()]
			var e := _spawn_enemy(lane_x, ENEMY_BASE_Z - i * 2.0)
			e.set_meta("speed", 6.0 + float(GameState.current_planet) * 0.05)

func _spawn_enemy(x: float, z: float) -> MeshInstance3D:	# Robust enemy instantiation (runtime load + fallback)
	var e: MeshInstance3D = null
	@warning_ignore("shadowed_variable")
	var paths := [
		"res://models/enemies/EnemyWasp.tscn",
		"res://models/enemies/EnemyManta.tscn",
		"res://models/enemies/EnemyLeech.tscn",
	]
	var tries := paths.size()
	while tries > 0 and e == null:
		var path: String = paths[randi() % paths.size()]
		var packed: Resource = load(path)
		if packed:
			var inst = packed.instantiate()
			if inst is MeshInstance3D:
				e = inst
		tries -= 1
	if e == null:
		e = MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.5
		cap.height = 2.0
		e.mesh = cap
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(1, 0.3, 0.3)
		mat.emission_energy_multiplier = 1.2
		e.material_override = mat
	var y := 0.0
	if player != null:
		y = player.position.y
	e.position = Vector3(x, y, z)
	var base_hp := 1 + int(GameState.current_planet * 0.15)
	e.set_meta("hp", base_hp)
	enemies.append(e)
	add_child(e)
	return e
func _spawn_boss() -> void:
	var b := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(2,2,2)
	b.mesh = cube
	b.material_override = _mat_unshaded(Color(1,0.8,0.2))
	b.position = Vector3(0, 0, ENEMY_BASE_Z - 15)
	b.set_meta("hp", 20 + int(GameState.current_planet * 0.5))
	b.set_meta("boss", true)
	enemies.append(b)
	world.add_child(b)
	boss_alive = true

func _shoot() -> void:
	var b := MeshInstance3D.new()
	b.mesh = CylinderMesh.new()
	b.scale = Vector3(0.1,0.1,0.1)
	b.material_override = _mat_unshaded(Color(0.8,1,0.8))
	b.position = player.position + Vector3(0,0,-1)
	var spd: float = 30.0 + float(GameState.player_stats["speed"]) * 0.5
	b.set_meta("vel", Vector3(0,0,-spd))
	b.set_meta("dmg", int(GameState.player_stats["damage"]))
	bullets.append(b)
	world.add_child(b)

func _tick_bullets(delta: float) -> void:
	for b in bullets:
		if not is_instance_valid(b): continue
		var vel: Vector3 = b.get_meta("vel")
		b.position += vel * delta
		if b.position.z < -80: b.queue_free()
	bullets = bullets.filter(func(n): return is_instance_valid(n))

func _tick_enemies(delta: float) -> void:
	for e in enemies:
		if not is_instance_valid(e): continue
		var speed: float = float(e.get_meta("speed")) if e.has_meta("speed") else 8.0
		e.position += Vector3(0,0, speed * delta)

		for b in bullets:
			if is_instance_valid(b):
				var is_boss: bool = bool(e.get_meta("boss")) if e.has_meta("boss") else false
				var hit_radius: float = 1.5 if is_boss else 0.8
				if b.position.distance_to(e.position) < hit_radius:
					var hp: int = int(e.get_meta("hp")) - int(b.get_meta("dmg"))
					e.set_meta("hp", hp)
					_hit_flash(b.position, is_boss)
					_do_shake(0.12 if is_boss else 0.06, 0.2 if is_boss else 0.12)
					b.queue_free()
					if hp <= 0:
						score += 500 if is_boss else 100
						_maybe_drop_loot(e.position)
						e.queue_free()
						if is_boss: boss_alive = false
						break

		if is_instance_valid(e) and e.position.z > 8:
			var hp_player: int = int(GameState.player_stats["health"]) - 10
			GameState.player_stats["health"] = max(0, hp_player)
			e.queue_free()
			if hp_player <= 0:
				_on_player_dead()

	enemies = enemies.filter(func(n): return is_instance_valid(n))

func _tick_loot(delta: float) -> void:
	for l in loot:
		if not is_instance_valid(l): continue
		var vel: Vector3 = l.get_meta("vel")
		l.position += vel * delta
		if l.position.distance_to(player.position) < 1.2:
			var typ: String = l.get_meta("type")
			_apply_loot(typ)
			_hit_flash(l.position)
			_do_shake(0.05, 0.08)
			l.queue_free()
	loot = loot.filter(func(n): return is_instance_valid(n))

func _apply_loot(typ: String) -> void:
	match typ:
		"HEALTH":
			GameState.player_stats["health"] = min(100, int(GameState.player_stats["health"]) + 10)
		"ARMOR":
			GameState.player_stats["armor"] = min(100, int(GameState.player_stats["armor"]) + 10)
		"SPEED":
			GameState.player_stats["speed"] = min(10.0, float(GameState.player_stats["speed"]) + 0.5)
		"FIRE_RATE":
			GameState.player_stats["fire_rate"] = min(20.0, float(GameState.player_stats["fire_rate"]) + 0.5)
		"DAMAGE":
			GameState.player_stats["damage"] = int(GameState.player_stats["damage"]) + 1
		_:
			pass

func _maybe_drop_loot(pos: Vector3) -> void:
	if randf() < 0.25:
		var l := MeshInstance3D.new()
		l.mesh = SphereMesh.new()
		l.scale = Vector3(0.4,0.4,0.4)
		l.material_override = _mat_unshaded(Color(0.2,1,0.6))
		l.position = pos + Vector3(0,0,2)
		l.set_meta("vel", Vector3(0,0,6))
		var types = ["HEALTH","ARMOR","SPEED","FIRE_RATE","DAMAGE"]
		l.set_meta("type", types[randi()%types.size()])
		loot.append(l)
		world.add_child(l)

func _on_player_dead() -> void:
	GameState.register_result(false, score, target)
	get_tree().change_scene_to_file("res://scenes/PlayMenu.tscn")

func _hit_flash(pos: Vector3, big := false) -> void:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.8,0.8) if big else Vector2(0.4,0.4)
	q.mesh = qm
	var m := StandardMaterial3D.new()
	m.resource_local_to_scene = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1,0.9,0.4,1.0)
	q.material_override = m
	q.position = pos
	world.add_child(q)
	var tw := create_tween()
	var end_col: Color = Color(m.albedo_color.r, m.albedo_color.g, m.albedo_color.b, 0.0)
	tw.tween_property(m, "albedo_color", end_col, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(Callable(q, "queue_free"))

func _do_shake(amp := 0.08, dur := 0.15) -> void:
	shake_amp = amp
	shake_t = dur

func _mat_unshaded(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	return m
