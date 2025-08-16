extends Node3D

# --- Cadencia de disparo (MUY lenta al inicio, mejora con upgrades) ---
const BASE_FIRE_INTERVAL: float = 2.40   # s entre disparos al inicio
const MIN_FIRE_INTERVAL: float = 0.50    # límite inferior claro
var _shoot_cooldown: float = 0.0

# --- Referencias (ajusta a tu escena si difiere) ---
@onready var muzzle: Node3D = $Player/Muzzle if has_node("Player/Muzzle") else self
var bullet_scene: PackedScene = null

# Evitar 'shadowed variable'
var mesh_paths: Array[String] = [
	"res://models/ship_default.glb",
	"res://models/ship_alt.glb"
]

func _ready() -> void:
	# Carga perezosa de la bala
	var candidates: Array[String] = ["res://scenes/Bullet.tscn", "res://scenes/Projectiles/Bullet.tscn"]
	for i in range(candidates.size()):
		var p: String = candidates[i]
		if ResourceLoader.exists(p):
			bullet_scene = load(p) as PackedScene
			break
	if bullet_scene == null:
		push_warning("Bullet.tscn no encontrado; disparo desactivado hasta que exista.")
	_shoot_cooldown = 0.0

func _physics_process(delta: float) -> void:
	_shoot_cooldown = max(0.0, _shoot_cooldown - delta)
	var shooting: bool = Input.is_action_pressed("shoot") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if shooting and _shoot_cooldown <= 0.0:
		_fire()
		var lvl: int = 0
		if typeof(GameState) != TYPE_NIL and GameState.has_method("get_upgrade_level"):
			lvl = int(GameState.get_upgrade_level("fire_rate"))
		var mult: float = pow(0.90, float(lvl))
		var interval: float = max(MIN_FIRE_INTERVAL, BASE_FIRE_INTERVAL * mult)
		_shoot_cooldown = interval

func _fire() -> void:
	if bullet_scene == null:
		return
	var b: Node3D = bullet_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(b)
	var xform: Transform3D = (muzzle if muzzle != null else self).global_transform
	b.global_transform = xform
	# rutas de ejemplo; evita 'paths' locales
	var mesh_paths_local: Array[String] = mesh_paths
	var pick: int = randi() % max(1, mesh_paths_local.size())
	var path: String = mesh_paths_local[pick]
	# var res: Resource = load(path)
