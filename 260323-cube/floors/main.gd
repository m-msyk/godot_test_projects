class_name Main extends Node

# Node references
@onready var current_level: Node = $CurrentLevel
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var elevator_ui: ElevatorUI = $ElevatorUI

# Lifecycle
func _ready() -> void:
	await get_tree().process_frame
	_connect_signals()
	_load_level_immediate("res://floors/b1.tscn")

# Signal connections
func _connect_signals() -> void:
	elevator_ui.floor_selected.connect(_on_floor_selected)

func _connect_elevators() -> void:
	for elevator in get_tree().get_nodes_in_group("interactable"):
		if elevator is Elevator:
			if not elevator.elevator_opened.is_connected(_on_elevator_opened):
				elevator.elevator_opened.connect(_on_elevator_opened)

# Signal handlers
func _on_floor_selected(floor_id: String) -> void:
	load_level("res://floors/" + floor_id + ".tscn")

func _on_elevator_opened() -> void:
	elevator_ui.open()

# Level loading
func _load_level_immediate(path: String) -> void:
	FloorManager.set_current_floor(path.get_file().get_basename())
	for child in current_level.get_children():
		child.queue_free()
	var level = load(path)
	current_level.add_child(level.instantiate())
	_connect_elevators()

func load_level(path: String) -> void:
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)
	await tween.finished

	_load_level_immediate(path)

	tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.5)
	await tween.finished
