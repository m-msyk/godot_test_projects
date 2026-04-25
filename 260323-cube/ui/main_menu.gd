class_name MainMenu extends Control

@onready var start_button: Button = $Panel/ButtonContainer/StartButton
@onready var exit_button: Button = $Panel/ButtonContainer/ExitButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_connect_signals()

func _connect_signals() -> void:
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://floors/main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
