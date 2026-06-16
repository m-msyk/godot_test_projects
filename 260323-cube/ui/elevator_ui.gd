class_name ElevatorUI extends Control

signal floor_selected(floor_id: String)

const FLOOR_BUTTON = preload("res://ui/floor_button.tscn")

@onready var floor_list: VBoxContainer = $Panel/FloorList

const FLOOR_NAMES: Dictionary = {
	"b1": "B1",
	"b2": "B2",
	"b3": "B3",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func open() -> void:
	_populate_floors()
	show()
	StateManager.set_state(StateManager.State.PARTIAL)

func close() -> void:
	hide()
	StateManager.set_state(StateManager.State.FREE)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()

func _populate_floors() -> void:
	for child in floor_list.get_children():
		child.queue_free()
	var buttons: Array = []
	var enabled_buttons: Array = []
	for floor_id in FLOOR_NAMES.keys():
		var button := FLOOR_BUTTON.instantiate()
		button.text = FLOOR_NAMES[floor_id]
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		var is_current = floor_id == FloorManager.current_floor
		var is_unlocked = FloorManager.is_floor_unlocked(floor_id)
		button.disabled = is_current or not is_unlocked
		if not button.disabled:
			button.pressed.connect(_on_floor_selected.bind(floor_id))
			enabled_buttons.append(button)
		floor_list.add_child(button)
		buttons.append(button)
	for i in enabled_buttons.size():
		var prev = enabled_buttons[(i - 1 + enabled_buttons.size()) % enabled_buttons.size()]
		var next = enabled_buttons[(i + 1) % enabled_buttons.size()]
		enabled_buttons[i].focus_neighbor_top = prev.get_path()
		enabled_buttons[i].focus_neighbor_bottom = next.get_path()
	if enabled_buttons.size() > 0:
		enabled_buttons[0].grab_focus()

## Emits [signal ElevatorUI.floor_selected] for [main.gd] to receive
func _on_floor_selected(floor_id: String) -> void:
	floor_selected.emit(floor_id)
	close()
