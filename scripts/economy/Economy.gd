extends Node

@export var fire_rate_step: float = 0.15
@export var fire_rate_max: float = 6.0
@export var coins_per_upgrade: int = 5
@export var points_to_coin: int = 100

var points: int = 0
var coins: int = 0
var fire_rate_level: int = 0

func base_fire_rate() -> float:
	var base: float = 1.0
	if typeof(get("GameState")) != TYPE_NIL:
		base = float(GameState.player_stats.get("fire_rate", 1.0))
	return base

func effective_fire_rate() -> float:
	return clamp(base_fire_rate() + float(fire_rate_level) * fire_rate_step, 0.5, fire_rate_max)

func add_points(n: int) -> void:
	points = max(0, points + n)

func convert_points_to_coins() -> int:
	var made: int = int(points / points_to_coin)
	if made > 0:
		coins += made
		points -= made * points_to_coin
	return made

func can_buy_fire_rate_upgrade() -> bool:
	var max_levels: int = int(ceil((fire_rate_max - 0.0) / max(0.0001, fire_rate_step)))
	return coins >= coins_per_upgrade and fire_rate_level < max_levels

func buy_fire_rate_upgrade() -> bool:
	if can_buy_fire_rate_upgrade():
		coins -= coins_per_upgrade
		fire_rate_level += 1
		return true
	return false
