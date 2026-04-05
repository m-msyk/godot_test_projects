class_name Main extends Node

@onready var current_level: Node = $CurrentLevel
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var elevator_ui: ElevatorUI = $ElevatorUI

func _ready() -> void:
	await get_tree().process_frame
	_load_level_immediate("res://floors/b1.tscn")
	_connect_signals()

func _connect_signals() -> void:
	elevator_ui.floor_selected.connect(_on_floor_selected)

func _on_floor_selected(floor_id: String) -> void:
	load_level("res://floors/" + floor_id + ".tscn")

func _load_level_immediate(path: String) -> void:
	FloorManager.set_current_floor(path.get_file().get_basename())
	for child in current_level.get_children():
		child.queue_free()
	var level = load(path)
	current_level.add_child(level.instantiate())

func load_level(path: String) -> void:
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)
	await tween.finished

	_load_level_immediate(path)

	tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.5)
	await tween.finished
