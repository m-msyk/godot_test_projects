class_name SaveMenuBase extends Control

@onready var floor_label: Label = $Panel/Content/LocationRow/FloorLabel
@onready var area_label: Label = $Panel/Content/LocationRow/AreaLabel
@onready var time_label: Label = $Panel/Content/TimeRow/TimeLabel
@onready var primary_button: Button = $Panel/Content/ButtonRow/PrimaryButton
@onready var secondary_button: Button = $Panel/Content/ButtonRow/SecondaryButton

func _ready() -> void:
	hide()
	_connect_signals()

func _connect_signals() -> void:
	primary_button.pressed.connect(_on_primary_pressed)
	secondary_button.pressed.connect(_on_secondary_pressed)

func populate(floor_id: String, area: String, time_seconds: float) -> void:
	floor_label.text = floor_id
	area_label.text = area
	time_label.text = _format_time(time_seconds)

func open() -> void:
	show()
	primary_button.grab_focus()

func close() -> void:
	hide()

func _format_time(seconds: float) -> String:
	var hours := int(seconds / 3600)
	var minutes := int(fmod(seconds, 3600) / 60)
	return "%02d:%02d" % [hours, minutes]

func _on_primary_pressed() -> void:
	pass  # overridden by child scenes

func _on_secondary_pressed() -> void:
	pass  # overridden by child scenes
