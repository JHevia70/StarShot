extends Node
# scripts/spawn/Spawner.gd
# Thin wrapper that delegates to Shooter's own spawn functions if present.
# Keeps your existing spawn logic intact but lets you move timings here.

var shooter: Node
var wave_timer: float = 0.0
var loot_timer: float = 0.0

@export var wave_interval: float = 3.5
@export var loot_interval: float = 5.0

func set_shooter(s: Node) -> void:
	shooter = s

func process(delta: float) -> void:
	wave_timer -= delta
	loot_timer -= delta
	if wave_timer <= 0.0:
		_spawn_wave_safe()
		wave_timer = wave_interval
	if loot_timer <= 0.0:
		_tick_loot_safe()
		loot_timer = loot_interval

func _spawn_wave_safe() -> void:
	if shooter and shooter.has_method("_spawn_wave"):
		shooter._spawn_wave()
	else:
		# Fallback: no-op to avoid breaking anything
		pass

func _tick_loot_safe() -> void:
	# Try shooter-side loot tick first
	if shooter and shooter.has_method("_tick_loot"):
		shooter._tick_loot(0.0) # many implementations ignore delta here
	elif shooter and shooter.has_method("_maybe_drop_loot"):
		shooter._maybe_drop_loot()
