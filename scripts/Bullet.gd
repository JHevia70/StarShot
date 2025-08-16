extends Area3D
@export var speed: float = 40.0
@export var lifetime: float = 2.0

func _ready() -> void:
	set_physics_process(true)
	# auto-destruir tras 'lifetime' segundos
	var t := get_tree().create_timer(lifetime)
	t.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	# avanza en dirección -Z local
	translate(Vector3(0,0,-speed * delta))
