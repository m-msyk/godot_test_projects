class_name ExitOption extends Button

signal exit_pressed

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	exit_pressed.emit()

func set_highlighted(highlighted: bool) -> void:
	add_theme_color_override("font_color", Color.YELLOW if highlighted else Color.WHITE)

func activate() -> void:
	pressed.emit()
