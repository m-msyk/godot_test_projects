class_name Main extends Node

@onready var current_level: Node = $CurrentLevel

func _ready() -> void:
	load_level("res://floors/b1.tscn")

func load_level(path: String) -> void:
	for child in current_level.get_children():
		child.queue_free()
	var level = load(path)
	current_level.add_child(level.instantiate())
