class_name CameraSensitivityOption extends HBoxContainer

## Emits the camera's rotation speed directly, in degrees/sec.
signal sensitivity_changed(value: float)

@onready var slider: HSlider = $HSlider
@onready var label: Label = $Label

func _ready() -> void:
	slider.value_changed.connect(_on_slider_changed)
	sensitivity_changed.emit(slider.value)

func _on_slider_changed(value: float) -> void:
	sensitivity_changed.emit(value)

func set_highlighted(highlighted: bool) -> void:
	label.add_theme_color_override("font_color", Color.YELLOW if highlighted else Color.WHITE)

func adjust(direction: int) -> void:
	slider.value += direction * slider.step
