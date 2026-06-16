class_name MenuComponent extends Node

signal sensitivity_changed(value: float)
signal resolution_changed(size: Vector2i, fullscreen: bool)

@onready var menu_ui: Control = $MenuUI
@onready var sensitivity_option: MouseSensitivityOption = $MenuUI/Panel/TabContainer/Settings/MouseSensitivityOption
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
		DisplayServer.window_set_size(size)
		var scale := size.x / 360
		CursorManager.set_cursor_for_scale(scale)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if Dialogic.current_timeline != null:
			return
		toggle_pause()

func toggle_pause() -> void:
	if menu_ui.visible:
		menu_ui.visible = false
		StateManager.set_state(StateManager.State.FREE)
	else:
		menu_ui.visible = true
		StateManager.set_state(StateManager.State.FROZEN)
