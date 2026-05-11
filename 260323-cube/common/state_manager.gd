extends Node

signal state_changed(new_state: State)

enum State {
	FREE,
	PARTIAL,
	FROZEN
}

var current_state: State = State.FREE

func _ready() -> void:
	_apply_state()

func set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	_apply_state()
	state_changed.emit(new_state)

func _apply_state() -> void:
	match current_state:
		State.FREE:
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		State.PARTIAL:
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		State.FROZEN:
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
