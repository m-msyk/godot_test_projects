class_name MenuComponent extends Node

signal sensitivity_changed(value: float)
signal resolution_changed(size: Vector2i, fullscreen: bool)

@onready var menu_ui: Control = $MenuUI
@onready var sensitivity_option: MouseSensitivityOption = $MenuUI/Panel/OptionsContainer/MouseSensitivityOption
@onready var resolution_option: ResolutionOption = $MenuUI/Panel/OptionsContainer/ResolutionOption
@onready var exit_option: ExitOption = $MenuUI/Panel/OptionsContainer/ExitOption

var is_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_ui.visible = false
	_connect_signals()

func _connect_signals() -> void:
	sensitivity_option.sensitivity_changed.connect(_on_sensitivity_changed)
	resolution_option.resolution_changed.connect(_on_resolution_changed)
	exit_option.exit_pressed.connect(_on_exit_pressed)

func _on_sensitivity_changed(value: float) -> void:
	sensitivity_changed.emit(value)

func _on_resolution_changed(size: Vector2i, fullscreen: bool) -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(size)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if Dialogic.current_timeline != null:
			return
		if get_tree().root.get_node("Main/ElevatorUI").visible:
			get_tree().root.get_node("Main/ElevatorUI").close()
			return
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	menu_ui.visible = is_paused
	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE if is_paused else Input.MOUSE_MODE_CAPTURED
	)
