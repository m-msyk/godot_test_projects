class_name NoteOffsetOption extends HBoxContainer

signal note_offset_changed(value: float)

const DEFAULT_OFFSET: float = 0.25

@onready var slider: HSlider = $HSlider
@onready var value_label: Label = $ValueLabel

func _ready() -> void:
	slider.min_value = -0.25   # 0ms effective
	slider.max_value = 0.75    # 500ms effective
	slider.step = 0.01
	slider.value = PlayerData.note_offset
	slider.value_changed.connect(_on_slider_changed)
	_update_label(PlayerData.note_offset)

func _on_slider_changed(value: float) -> void:
	print("slider changed to: ", value, " | note_offset now: ", value)
	PlayerData.note_offset = value
	_update_label(value)
	note_offset_changed.emit(value)

func _update_label(value: float) -> void:
	var relative := (value - DEFAULT_OFFSET) * 1000
	value_label.text = "%+.0fms" % relative
