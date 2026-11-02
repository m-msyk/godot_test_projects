class_name ResolutionOption extends HBoxContainer

signal resolution_changed(size: Vector2i, fullscreen: bool)

@onready var option_button: OptionButton = $ValueRow/OptionButton
@onready var label: Label = $Label

const RESOLUTIONS := [
	Vector2i(360, 240),
	Vector2i(720, 480),
	Vector2i(1080, 720),
	Vector2i(1440, 960),
]

func _ready() -> void:
	_populate_options()
	option_button.selected = 2 # Default becomes 720 x 480
	option_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hide_dropdown_arrow()
	_style_popup()

	_connect_signals()

## The flanking LeftArrow/RightArrow icons (rotated 90 degrees each way)
## indicate this is stepped with LEFT/RIGHT, so the native dropdown arrow
## — which no longer opens anything, since the mouse is disabled — is hidden.
func _hide_dropdown_arrow() -> void:
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var blank := ImageTexture.create_from_image(img)
	option_button.add_theme_icon_override("arrow", blank)

func _style_popup() -> void:
	var popup := option_button.get_popup()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color.BLACK
	panel_style.border_color = Color.WHITE
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(0)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color.TRANSPARENT
	hover_style.border_color = Color.TRANSPARENT
	hover_style.set_border_width_all(0)

	popup.add_theme_stylebox_override("panel", panel_style)
	popup.add_theme_stylebox_override("hover", hover_style)
	popup.add_theme_color_override("font_color", Color.WHITE)
	popup.add_theme_color_override("font_hover_color", Color.YELLOW)

	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var blank := ImageTexture.create_from_image(img)

	popup.add_theme_icon_override("checked", blank)
	popup.add_theme_icon_override("unchecked", blank)
	popup.add_theme_icon_override("radio_checked", blank)
	popup.add_theme_icon_override("radio_unchecked", blank)

func _populate_options() -> void:
	option_button.add_item("360 x 240 (1x)")
	option_button.add_item("720 x 480 (2x)")
	option_button.add_item("1080 x 720 (3x)")
	option_button.add_item("1440 x 960 (4x)")
	option_button.add_item("Fullscreen")

func _connect_signals() -> void:
	option_button.item_selected.connect(_on_item_selected)

func _on_item_selected(index: int) -> void:
	if index == RESOLUTIONS.size():
		resolution_changed.emit(Vector2i.ZERO, true)
	else:
		resolution_changed.emit(RESOLUTIONS[index], false)

func set_highlighted(highlighted: bool) -> void:
	label.add_theme_color_override("font_color", Color.YELLOW if highlighted else Color.WHITE)

func adjust(direction: int) -> void:
	var count := option_button.item_count
	if count <= 0:
		return
	var new_index: int = clampi(option_button.selected + direction, 0, count - 1)
	if new_index == option_button.selected:
		return
	option_button.select(new_index)
	_on_item_selected(new_index)
