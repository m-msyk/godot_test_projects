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
	SaveManager.game_reset.connect(reset)
	_create_mouse_blocker()

## The game is keyboard-only: swallow every mouse event globally so the
## (hidden) cursor can never click or drag a Control.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()

## A raw _input() swallow isn't enough on its own — Control nodes receive
## clicks/hovers through the engine's own GUI hit-test, which runs
## independently of script input order. A full-screen invisible Control
## with mouse_filter=STOP physically absorbs the hit test itself, so
## nothing beneath it (buttons, sliders, dropdowns, anywhere in the game)
## can ever be clicked or hovered, regardless of scene.
func _create_mouse_blocker() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4096
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var blocker := Control.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(blocker)
	add_child(layer)

func initialize() -> void:
	current_state = State.FREE
	_apply_state()
	state_changed.emit(State.FREE)

func reset() -> void:
	current_state = State.FREE
	_apply_state()
	state_changed.emit(State.FREE)

func set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	_apply_state()
	state_changed.emit(new_state)

func _apply_state() -> void:
	print("applying state: ", current_state)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	match current_state:
		State.FREE:
			get_tree().paused = false
		State.PARTIAL:
			get_tree().paused = false
		State.FROZEN:
			get_tree().paused = true
