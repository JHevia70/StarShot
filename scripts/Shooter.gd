extends Node3D

# --- Cadencia de disparo (lenta al inicio, mejora con upgrades) ---
const BASE_FIRE_INTERVAL: float = 1.60   # más lento al inicio
const MIN_FIRE_INTERVAL: float = 0.25    # límite inferior
var _shoot_cooldown: float = 0.0

# --- Referencias (ajusta a tu escena si difiere) ---
@onready var muzzle: Node3D = $Player/Muzzle if has_node("Player/Muzzle") else self
var bullet_scene: PackedScene = null

# Rutas de ejemplo para mallas u otros recursos; evita 'paths' para no sombrear
var mesh_paths: Array[String] = [
	"res://models/ship_default.glb",
	"res://models/ship_alt.glb"
]

func _ready() -> void:
	# Carga perezosa de la bala para evitar fallos de preload si no existe
	var candidates: Array[String] = ["res://scenes/Bullet.tscn", "res://scenes/Projectiles/Bullet.tscn"]
	for p in candidates:
		if ResourceLoader.exists(p):
			bullet_scene = load(p) as PackedScene
			break
	if bullet_scene == null:
		push_warning("Bullet.tscn no encontrado; disparo desactivado hasta que exista.")
	# Asegurar cooldown inicial
	_shoot_cooldown = 0.0

func _physics_process(delta: float) -> void:
	# Cooldown
	_shoot_cooldown = max(0.0, _shoot_cooldown - delta)
	# Entrada
	var shooting := Input.is_action_pressed("shoot") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if shooting and _shoot_cooldown <= 0.0:
		_fire()
		# factor por upgrades (si existe GameState.get_upgrade_level("fire_rate"))
		var lvl := 0
		if typeof(GameState) != TYPE_NIL and GameState.has_method("get_upgrade_level"):
			lvl = int(GameState.get_upgrade_level("fire_rate"))
		var mult := pow(0.90, float(lvl))
		var interval := max(MIN_FIRE_INTERVAL, BASE_FIRE_INTERVAL * mult)
		_shoot_cooldown = interval

func _fire() -> void:
	if bullet_scene == null:
		return
	var b := bullet_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(b)
	# Salida desde muzzle (si no hay, usa self)
	var xform := (muzzle if muzzle != null else self).global_transform
	b.global_transform = xform
	# Ejemplo de uso de rutas sin sombreamiento local
	var mesh_paths_local: Array[String] = mesh_paths
	var pick := randi() % max(1, mesh_paths_local.size())
	var path: String = mesh_paths_local[pick]
	# var res := load(path) # opcional

func _unhandled_input(event: InputEvent) -> void:
	pass
