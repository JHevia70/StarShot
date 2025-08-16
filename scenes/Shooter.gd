extends Node3D

# --- Cadencia (MUY lenta al inicio) ---
@export var initial_fire_interval: float = 3.50   # s entre disparos al inicio
@export var min_fire_interval: float = 0.70       # límite inferior
@export var fire_rate_decay_per_level: float = 0.90  # -10% por nivel

var _shoot_cooldown: float = 0.0

# --- Referencias ---
@onready var muzzle: Node3D = $Player/Muzzle if has_node("Player/Muzzle") else self
var bullet_scene: PackedScene = null

func _ready() -> void:
	# Carga perezosa: solo ruta en 'scenes' como has pedido
	var p: String = "res://scenes/Bullet.tscn"
	if ResourceLoader.exists(p):
		bullet_scene = load(p) as PackedScene
	else:
		push_warning("res://scenes/Bullet.tscn no encontrado; disparo desactivado hasta que exista.")
	_shoot_cooldown = 0.0

func _physics_process(delta: float) -> void:
	_shoot_cooldown = max(0.0, _shoot_cooldown - delta)
	var shooting: bool = Input.is_action_pressed("shoot") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if shooting and _shoot_cooldown <= 0.0:
		_fire()
		_shoot_cooldown = _effective_interval()

func _effective_interval() -> float:
	var base_interval: float = initial_fire_interval
	var lvl: int = 0
	if typeof(GameState) != TYPE_NIL and GameState.has_method("get_upgrade_level"):
		lvl = int(GameState.get_upgrade_level("fire_rate"))
	var mult: float = pow(fire_rate_decay_per_level, float(lvl))
	return max(min_fire_interval, base_interval * mult)

func _fire() -> void:
	if bullet_scene == null:
		return
	var b: Node3D = bullet_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(b)
	var xform: Transform3D = (muzzle if muzzle != null else self).global_transform
	b.global_transform = xform
