class_name InputComponent extends Node

var move_dir: Vector2 = Vector2.ZERO
var jump_pressed := false
var mouse_delta: Vector2 = Vector2.ZERO
var disabled := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_connect_signals()

func _connect_signals() -> void:
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)

func _on_dialogue_started() -> void:
	disabled = true

func _on_dialogue_ended() -> void:
	disabled = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not disabled:
			mouse_delta = event.relative

func update() -> void:
	if disabled:
		move_dir = Vector2.ZERO
		jump_pressed = false
		mouse_delta = Vector2.ZERO
		return
	move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	jump_pressed = Input.is_action_just_pressed("jump")
	mouse_delta = Vector2.ZERO
