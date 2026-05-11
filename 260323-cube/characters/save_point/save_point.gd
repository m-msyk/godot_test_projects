class_name SavePoint extends CharacterBody3D

signal save_requested(save_point_id: String, floor_id: String, area: String)

@export var save_point_id: String = ""
@export var spawn_offset: float = 0.01
@export var timeline: DialogicTimeline

@onready var dialogic_component: DialogicComponent = $DialogicComponent

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("interactable")
	add_to_group("save_point")
	dialogic_component.timeline = timeline
	_connect_signals()

func _connect_signals() -> void:
	dialogic_component.dialogic_signal_received.connect(_on_dialogic_signal)

func start_dialogue() -> void:
	dialogic_component.start_dialogue()

func _on_dialogic_signal(argument: String) -> void:
	var parts = argument.split(":")
	if parts.size() < 1:
		return
	match parts[0]:
		"save_game":
			if parts.size() >= 4:
				save_requested.emit(parts[1], parts[2], parts[3])

func get_spawn_position() -> Vector3:
	return global_position + (-global_basis.z * spawn_offset)
