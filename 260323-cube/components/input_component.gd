class_name InputComponent extends Node

var move_dir: Vector2 = Vector2.ZERO
var jump_pressed := false
var mouse_delta: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta = event.relative

func update() -> void:
	move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	jump_pressed = Input.is_action_just_pressed("jump")
	mouse_delta = Vector2.ZERO  # Reset each frame after other systems have read it
