class_name ModRow extends HBoxContainer

signal purchase_requested(mod_id: String)

@onready var name_label: Label = $NameLabel
@onready var level_label: Label = $LevelLabel
@onready var cost_label: Label = $CostLabel
@onready var buy_button: Button = $BuyButton

var _mod: Mod
var _description: String

func setup(mod: Mod) -> void:
	_mod = mod
	_description = mod.description
	name_label.text = mod.display_name
	_refresh()
	buy_button.pressed.connect(_on_buy_pressed)

func _refresh() -> void:
	var level: int = PlayerData.upgrades.get(_mod.mod_id, 0)
	var cost: int = PlayerData.get_upgrade_cost(_mod.mod_id)
	level_label.text = "Lv. %d" % level
	cost_label.text = "%d pts" % cost
	buy_button.disabled = not PlayerData.can_afford(_mod.mod_id)
	modulate = Color(1, 1, 1, 1) if PlayerData.can_afford(_mod.mod_id) else Color(0.5, 0.5, 0.5, 1)

func get_description() -> String:
	return _description

func set_highlighted(highlighted: bool) -> void:
	name_label.add_theme_color_override("font_color",
		Color.YELLOW if highlighted else Color.WHITE)

func _on_buy_pressed() -> void:
	purchase_requested.emit(_mod.mod_id)
