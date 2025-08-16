extends Control

# Finder robusto para dos jerarquías posibles (con/sin Panel)
func _find(a: String, b: String) -> Node:
	var n: Node = get_node_or_null(a)
	if n == null:
		n = get_node_or_null(b)
	return n

@onready var suns_value: Label = _find("Panel/VBox/Suns/SunsValue", "VBox/Suns/SunsValue") as Label
@onready var points_value: Label = _find("Panel/VBox/Points/PointsValue", "VBox/Points/PointsValue") as Label

@onready var fr_level: Label = _find("Panel/VBox/HFireRate/Level", "VBox/HFireRate/Level") as Label
@onready var dmg_level: Label = _find("Panel/VBox/HDamage/Level", "VBox/HDamage/Level") as Label
@onready var spd_level: Label = _find("Panel/VBox/HSpeed/Level", "VBox/HSpeed/Level") as Label
@onready var arm_level: Label = _find("Panel/VBox/HArmor/Level", "VBox/HArmor/Level") as Label

@onready var btn_fire: Button = _find("Panel/VBox/HFireRate/Buy", "VBox/HFireRate/Buy") as Button
@onready var btn_dmg: Button = _find("Panel/VBox/HDamage/Buy", "VBox/HDamage/Buy") as Button
@onready var btn_spd: Button = _find("Panel/VBox/HSpeed/Buy", "VBox/HSpeed/Buy") as Button
@onready var btn_arm: Button = _find("Panel/VBox/HArmor/Buy", "VBox/HArmor/Buy") as Button
@onready var btn_close: Button = _find("Panel/VBox/Close", "VBox/Close") as Button

@onready var spin_suns: SpinBox = _find("Panel/VBox/BuySuns/SunAmount", "VBox/BuySuns/SunAmount") as SpinBox
@onready var lbl_cost: Label = _find("Panel/VBox/BuySuns/CostPoints", "VBox/BuySuns/CostPoints") as Label
@onready var btn_buy_suns: Button = _find("Panel/VBox/BuySuns/DoBuySuns", "VBox/BuySuns/DoBuySuns") as Button

func _ready() -> void:
	if btn_fire != null:
		btn_fire.pressed.connect(_on_buy_fire_rate)
	if btn_dmg != null:
		btn_dmg.pressed.connect(_on_buy_damage)
	if btn_spd != null:
		btn_spd.pressed.connect(_on_buy_speed)
	if btn_arm != null:
		btn_arm.pressed.connect(_on_buy_armor)
	if btn_close != null:
		btn_close.pressed.connect(func (): queue_free())
	if btn_buy_suns != null:
		btn_buy_suns.pressed.connect(_on_buy_suns)
	if spin_suns != null:
		spin_suns.value_changed.connect(_on_spin_changed)
	_refresh()

func _refresh() -> void:
	if suns_value != null:
		suns_value.text = str(GameState.get_suns())
	if points_value != null:
		points_value.text = str(GameState.get_points())
	if fr_level != null:
		fr_level.text = "LVL %d" % GameState.get_upgrade_level("fire_rate")
	if dmg_level != null:
		dmg_level.text = "LVL %d" % GameState.get_upgrade_level("damage")
	if spd_level != null:
		spd_level.text = "LVL %d" % GameState.get_upgrade_level("speed")
	if arm_level != null:
		arm_level.text = "LVL %d" % GameState.get_upgrade_level("armor")
	_refresh_costs()

func _refresh_costs() -> void:
	var s: int = GameState.get_suns()
	var fr_cost: int = GameState.get_upgrade_cost("fire_rate")
	var dm_cost: int = GameState.get_upgrade_cost("damage")
	var sp_cost: int = GameState.get_upgrade_cost("speed")
	var ar_cost: int = GameState.get_upgrade_cost("armor")

	if btn_fire != null:
		btn_fire.text = "Comprar (%d)" % fr_cost
		var fr_max: bool = GameState.get_upgrade_level("fire_rate") >= 10
		btn_fire.disabled = (s < fr_cost) or fr_max
	if btn_dmg != null:
		btn_dmg.text = "Comprar (%d)" % dm_cost
		var dm_max: bool = GameState.get_upgrade_level("damage") >= 10
		btn_dmg.disabled = (s < dm_cost) or dm_max
	if btn_spd != null:
		btn_spd.text = "Comprar (%d)" % sp_cost
		var sp_max: bool = GameState.get_upgrade_level("speed") >= 10
		btn_spd.disabled = (s < sp_cost) or sp_max
	if btn_arm != null:
		btn_arm.text = "Comprar (%d)" % ar_cost
		var ar_max: bool = GameState.get_upgrade_level("armor") >= 10
		btn_arm.disabled = (s < ar_cost) or ar_max

	if lbl_cost != null and spin_suns != null:
		var price: int = GameState.get_sun_price_in_points()
		var count: int = int(spin_suns.value)
		var total: int = price * count
		lbl_cost.text = "Coste: %d pts" % total
		var max_buy: int = int(GameState.get_points() / price)
		spin_suns.max_value = max_buy

func _buy(stat: String) -> void:
	var ok: bool = GameState.buy_upgrade(stat)
	if ok:
		_refresh()
	else:
		push_warning("No tienes suns suficientes o alcanzaste el nivel máximo")

func _on_buy_suns() -> void:
	if spin_suns == null:
		return
	var count: int = int(spin_suns.value)
	if count <= 0:
		return
	var ok: bool = GameState.convert_points_to_suns(count)
	if ok:
		var d: AcceptDialog = AcceptDialog.new()
		d.dialog_text = "Has comprado %d suns." % count
		add_child(d)
		d.popup_centered()
		_refresh()
	else:
		push_warning("No hay puntos suficientes")

func _on_spin_changed(val: float) -> void:
	_refresh_costs()

func _on_buy_fire_rate() -> void:
	_buy("fire_rate")

func _on_buy_damage() -> void:
	_buy("damage")

func _on_buy_speed() -> void:
	_buy("speed")

func _on_buy_armor() -> void:
	_buy("armor")

