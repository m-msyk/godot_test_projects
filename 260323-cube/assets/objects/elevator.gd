class_name Elevator extends StaticBody3D

@export var destination: String = "res://floors/b2.tscn"

func _ready() -> void:
	add_to_group("interactable")

func interact() -> void:
	var elevator_ui = get_tree().root.get_node("Main/ElevatorUI")
	elevator_ui.open()
