class_name ResolutionOption extends HBoxContainer

signal resolution_changed(size: Vector2i, fullscreen: bool)

@onready var option_button: OptionButton = $OptionButton

@export var drop_down: Texture2D
@export var drop_down_highlight: Texture2D

const RESOLUTIONS := [
	Vector2i(360, 240),
	Vector2i(720, 480),
	Vector2i(1080, 720),
	Vector2i(1440, 960),
]

func _ready() -> void:
	_populate_options()
	option_button.selected = 2 # Default becomes 720 x 480
	option_button.add_theme_icon_override("arrow", drop_down)
	_style_popup()

	_connect_signals()

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
	option_button.mouse_entered.connect(_on_mouse_entered)
	option_button.mouse_exited.connect(_on_mouse_exited)

func _on_item_selected(index: int) -> void:
	if index == RESOLUTIONS.size():
		resolution_changed.emit(Vector2i.ZERO, true)
	else:
		resolution_changed.emit(RESOLUTIONS[index], false)

func _on_mouse_entered() -> void:
	option_button.add_theme_icon_override("arrow", drop_down_highlight)

func _on_mouse_exited() -> void:
	option_button.add_theme_icon_override("arrow", drop_down)
