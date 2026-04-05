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

func close() -> void:
	hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		close()
		get_viewport().set_input_as_handled()

func _populate_floors() -> void:
	for child in floor_list.get_children():
		child.queue_free()

	var first_enabled: Button = null

	for floor_id in FLOOR_NAMES.keys():
		var button := FLOOR_BUTTON.instantiate()
		button.text = FLOOR_NAMES[floor_id]
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		var is_current = floor_id == FloorManager.current_floor
		var is_unlocked = FloorManager.is_floor_unlocked(floor_id)
		button.disabled = is_current or not is_unlocked
		if not button.disabled:
			button.pressed.connect(_on_floor_selected.bind(floor_id))
			if first_enabled == null:
				first_enabled = button
		floor_list.add_child(button)

	if first_enabled:
		first_enabled.grab_focus()

func _on_floor_selected(floor_id: String) -> void:
	floor_selected.emit(floor_id)
	close()
