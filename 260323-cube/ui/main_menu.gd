class_name MainMenu extends Control

@onready var start_button: Button = $Panel/ButtonContainer/StartButton
@onready var exit_button: Button = $Panel/ButtonContainer/ExitButton
@onready var save_load_menu: SaveLoadMenu = $SaveLoadMenu

var _fading := false

func _ready() -> void:
	_connect_signals()
	_update_start_button()
	await ScreenFade.fade_from_black()
	start_button.grab_focus()

func _connect_signals() -> void:
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _input(event: InputEvent) -> void:
	if _fading:
		get_viewport().set_input_as_handled()

func _update_start_button() -> void:
	if SaveManager.save_exists():
		start_button.text = "Continue"
	else:
		start_button.text = "Start Game"

func _on_start_pressed() -> void:
	if SaveManager.save_exists():
		save_load_menu.open_with_data()
	else:
		_fading = true
		await ScreenFade.fade_to_black()
		get_tree().change_scene_to_file("res://floors/main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
