extends Node

const TOTAL_PLANETS := 100
const MIN_PER_STAR := 5
const MAX_PER_STAR := 10
const SAVE_PATH := "user://save.json"

var rng_seed: int = 0
var highest_unlocked: int = -1
var current_planet: int = -1

var planets: Array[Dictionary] = []
var systems: Array[Dictionary] = []


var points_balance: int = 0
var suns: int = 0
var upgrades: Dictionary = {"fire_rate": 0, "damage": 0, "speed": 0, "armor": 0}
const UPGRADE_BASE_PRICE: Dictionary = {"fire_rate": 5, "damage": 5, "speed": 5, "armor": 5}
const UPGRADE_MAX_LEVEL: int = 10
var last_result_message: String = ""

var player_stats: Dictionary = {
	"health": 100,
	"armor": 0,
	"speed": 8.0,
	"fire_rate": 1.0,
	"damage": 10
}

func _ready() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		_load()
	else:
		highest_unlocked = -1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) and highest_unlocked >= 0

func new_game() -> void:
	rng_seed = randi()
	_gen_galaxy(rng_seed)
	highest_unlocked = 0
	current_planet = 0
	_reset_stats()
	_save()

func continue_game() -> void:
	if not has_save():
		return
	current_planet = clamp(highest_unlocked, 0, TOTAL_PLANETS-1)

func complete_planet(planet_id: int, score: int) -> void:
	var p: Dictionary = planets[planet_id]
	var req: int = int(p.get("required_score", 0))
	if score >= req:
		if highest_unlocked <= planet_id and planet_id + 1 < TOTAL_PLANETS:
			highest_unlocked = planet_id + 1
		_save()

func required_score_for(planet_id:int) -> int:
	var p: Dictionary = planets[planet_id]
	return int(p.get("required_score", 0))

func is_unlocked(planet_id:int) -> bool:
	return planet_id <= highest_unlocked

func planets_in_system(sys_id:int) -> Array:
	var s: Dictionary = systems[sys_id]
	var arr: Array[int] = []
	var first:int = int(s.get("first_pid", 0))
	var last:int = int(s.get("last_pid", -1))
	for pid in range(first, last + 1):
		arr.append(pid)
	return arr

func system_count() -> int:
	return systems.size()

# ---------- stats ----------
func _reset_stats() -> void:
	player_stats = {
		"health": 100,
		"armor": 0,
		"speed": 8.0,
		"fire_rate": 6.0,
		"damage": 10
	}

func apply_upgrade(t:String, amount: float) -> void:
	match t:
		"HEALTH":
			player_stats["health"] = int(player_stats.get("health", 100)) + int(amount)
		"ARMOR":
			player_stats["armor"] = int(player_stats.get("armor", 0)) + int(amount)
		"SPEED":
			player_stats["speed"] = float(player_stats.get("speed", 8.0)) + amount * 0.1
		"FIRE_RATE":
			player_stats["fire_rate"] = float(player_stats.get("fire_rate", 6.0)) + amount * 0.1
		"DAMAGE":
			player_stats["damage"] = int(player_stats.get("damage", 10)) + int(amount * 0.5)
	_save()

# ---------- persistencia ----------
func _save() -> void:
	var d: Dictionary = {
		"seed": rng_seed,
		"highest_unlocked": highest_unlocked,
		"player_stats": player_stats,
		"points_balance": points_balance,
		"suns": suns,
		"upgrades": upgrades
	}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))

func _load() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) == TYPE_DICTIONARY:
		rng_seed = int(d.get("seed", 0))
		highest_unlocked = int(d.get("highest_unlocked", -1))
		player_stats = d.get("player_stats", player_stats)
		points_balance = int(d.get("points_balance", 0))
		suns = int(d.get("suns", 0))
		upgrades = d.get("upgrades", upgrades)
		_gen_galaxy(rng_seed)
	else:
		highest_unlocked = -1

# ---------- generación de galaxia ----------
func _gen_galaxy(seed_in:int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_in
	planets.clear()
	systems.clear()
	var remaining: int = TOTAL_PLANETS
	var sys_id: int = 0
	var pid: int = 0
	while remaining > 0:
		var count: int = clamp(rng.randi_range(MIN_PER_STAR, MAX_PER_STAR), 1, remaining)
		var first_pid: int = pid
		for i in range(count):
			var required: int = 800 + pid * 180
			var diff: float = 1.0 + float(pid) * 0.06
			planets.append({
				"id": pid,
				"system_id": sys_id,
				"required_score": required,
				"difficulty": diff
			})
			pid += 1
		systems.append({ "id": sys_id, "first_pid": first_pid, "last_pid": pid - 1 })
		remaining = TOTAL_PLANETS - pid
		sys_id += 1


# ---------- puntos, suns y upgrades ----------
func add_points(delta: int) -> void:
	points_balance = max(0, points_balance + delta)
	_save()

func get_points() -> int:
	return points_balance

func get_sun_price_in_points() -> int:
	return 150

func convert_points_to_suns(count: int) -> bool:
	var price_per := get_sun_price_in_points()
	if count <= 0:
		return false
	var total_cost := count * price_per
	if points_balance < total_cost:
		return false
	points_balance -= total_cost
	suns += count
	_save()
	return true

func get_suns() -> int:
	return suns

func get_upgrade_level(stat: String) -> int:
	return int(upgrades.get(stat, 0))

func get_upgrade_cost(stat: String) -> int:
	var base := int(UPGRADE_BASE_PRICE.get(stat, 5))
	var lvl := int(upgrades.get(stat, 0))
	return base * (lvl + 1)

func buy_upgrade(stat: String) -> bool:
	var lvl := int(upgrades.get(stat, 0))
	if lvl >= UPGRADE_MAX_LEVEL:
		return false
	var cost := get_upgrade_cost(stat)
	if suns < cost:
		return false
	suns -= cost
	upgrades[stat] = lvl + 1
	match stat:
		"fire_rate":
			player_stats["fire_rate"] = min(25.0, float(player_stats.get("fire_rate", 1.0)) + 0.25)
		"damage":
			player_stats["damage"] = int(player_stats.get("damage", 10)) + 2
		"speed":
			player_stats["speed"] = min(15.0, float(player_stats.get("speed", 8.0)) + 0.2)
		"armor":
			player_stats["armor"] = int(player_stats.get("armor", 0)) + 10
		_:
			pass
	_save()
	return true

# Mensaje de resultado (victoria/derrota)
func register_result(win: bool, score: int, _target: int) -> void:
	if win:
		add_points(score)
		last_result_message = "¡Bien hecho! Has ganado %d puntos." % score
	else:
		var loss: int = score >> 1  # floor(score/2) sin floats ni Variant
		if loss < 1:
			loss = 1
		var real_loss: int = points_balance if points_balance < loss else loss
		if real_loss > 0:
			add_points(-real_loss)
		last_result_message = "Derrota. Has perdido %d puntos." % real_loss
	_save()

func consume_result_message() -> String:
	var msg := last_result_message
	last_result_message = ""
	return msg
