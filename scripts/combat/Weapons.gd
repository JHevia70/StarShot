extends Node

var economy: Node = null

func _init(e: Node = null) -> void:
	economy = e

func effective_fire_rate() -> float:
	if economy and economy.has_method("effective_fire_rate"):
		return economy.effective_fire_rate()
	var base: float = 1.0
	if typeof(get("GameState")) != TYPE_NIL:
		base = float(GameState.player_stats.get("fire_rate", 1.0))
	return max(0.5, base)
