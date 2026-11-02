class_name ReelProgressComponent extends Node

signal progress_changed(current: int, threshold: int)
signal reeled_in()

@export var catch_threshold: int = 30

var current_progress: int

func _ready() -> void:
	current_progress = 0

func reset() -> void:
	current_progress = 0
	progress_changed.emit(current_progress, catch_threshold)

func add_progress(amount: int) -> void:
	current_progress = min(current_progress + amount, catch_threshold)
	progress_changed.emit(current_progress, catch_threshold)
	if current_progress >= catch_threshold:
		reeled_in.emit()
