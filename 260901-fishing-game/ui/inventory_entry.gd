class_name InventoryEntry extends VBoxContainer

@onready var icon_rect: TextureRect = $Row/Icon
@onready var fish_name_label: Label = $Row/FishName
@onready var count_label: Label = $Row/Count

var _description: String

func setup(species: FishSpecies, count: int) -> void:
	icon_rect.texture = species.icon
	fish_name_label.text = species.display_name
	count_label.text = "x%d" % count
	var largest := PlayerData.get_largest_catch(species.id)
	_description = "%s\nHeld: x%d\nLargest caught: %.1f cm" % [species.display_name, count, largest]

func get_description() -> String:
	return _description

func set_highlighted(highlighted: bool) -> void:
	fish_name_label.add_theme_color_override("font_color",
		Color.YELLOW if highlighted else Color.WHITE)
