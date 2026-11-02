class_name MenuComponent extends Node

signal sensitivity_changed(value: float)
signal resolution_changed(size: Vector2i, fullscreen: bool)

@onready var menu_ui: Control = $MenuUI
@onready var sensitivity_option: CameraSensitivityOption = $MenuUI/Panel/TabContainer/Settings/CameraSensitivityOption
@onready var resolution_option: ResolutionOption = $MenuUI/Panel/TabContainer/Settings/ResolutionOption
@onready var exit_option: ExitOption = $MenuUI/Panel/TabContainer/Settings/ExitOption

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
		var screen_size := DisplayServer.screen_get_size()
		var scale := screen_size.x / 360
		CursorManager.set_cursor_for_scale(scale)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_resize_window_from_center(size)
		var scale := size.x / 360
		CursorManager.set_cursor_for_scale(scale)

## Resizes the OS window while keeping its center point fixed, instead of
## the default behavior of growing/shrinking from the top-left corner.
func _resize_window_from_center(size: Vector2i) -> void:
	var old_size := DisplayServer.window_get_size()
	var old_position := DisplayServer.window_get_position()
	var center := old_position + old_size / 2
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(center - size / 2)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if menu_ui.visible:
			toggle_pause()
			return
		if Dialogic.current_timeline != null:
			return
		if StateManager.current_state == StateManager.State.FROZEN:
			return
		toggle_pause()

func toggle_pause() -> void:
	if menu_ui.visible:
		menu_ui.visible = false
		StateManager.set_state(StateManager.State.FREE)
		MusicManager.set_menu_filter_active(false)
	else:
		menu_ui.visible = true
		StateManager.set_state(StateManager.State.FROZEN)
		MusicManager.set_menu_filter_active(true)
