class_name InputComponent extends Node

var move_dir: Vector2 = Vector2.ZERO
var jump_pressed := false

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	StateManager.state_changed.connect(_on_state_changed)

func _on_state_changed(new_state: StateManager.State) -> void:
	if new_state != StateManager.State.FREE:
		move_dir = Vector2.ZERO
		jump_pressed = false

func update() -> void:
	if StateManager.current_state != StateManager.State.FREE:
		move_dir = Vector2.ZERO
		jump_pressed = false
		return
	move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	jump_pressed = Input.is_action_just_pressed("jump")
