extends Node
# scripts/ui/HUD.gd
# Lightweight HUD that shows fire rate, HP y (si existen) puntos/monedas.
# No toca tu HUD actual; se añade por encima con CanvasLayer.

var layer: CanvasLayer
var label: Label

func _ready() -> void:
	layer = CanvasLayer.new()
	add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color(0,0,0,0.3)
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect.size_flags_vertical = Control.SIZE_FILL
	rect.anchor_left = 0.0
	rect.anchor_top = 0.0
	rect.anchor_right = 1.0
	rect.anchor_bottom = 0.0
	rect.offset_bottom = 28
	layer.add_child(rect)
	label = Label.new()
	label.text = "HUD"
	label.position = Vector2(8, 4)
	layer.add_child(label)

func _process(delta: float) -> void:
	var hp := 0
	var fire_rate := 0.0
	var points := 0
	var coins := 0

	if Engine.has_singleton("GameState"):
		var gs = GameState.player_stats
		if typeof(gs) == TYPE_DICTIONARY:
			if gs.has("hp"): hp = int(gs["hp"])
			if gs.has("fire_rate"): fire_rate = float(gs["fire_rate"])
			if gs.has("points"): points = int(gs["points"])
			if gs.has("coins"): coins = int(gs["coins"])

	label.text = "HP:%d  FR:%.2f  Pts:%d  Coins:%d" % [hp, fire_rate, points, coins]
