class_name MouseSensitivityOption extends HBoxContainer

signal sensitivity_changed(value: float)

@onready var slider: HSlider = $HSlider

func _ready() -> void:
	slider.value_changed.connect(_on_slider_changed)

func _on_slider_changed(value: float) -> void:
	sensitivity_changed.emit(value)
