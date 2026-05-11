class_name Elevator extends StaticBody3D

signal elevator_opened

@export var destination: String = "res://floors/b2.tscn"

func _ready() -> void:
	add_to_group("interactable")

func interact() -> void:
	print("interact called, emitting elevator_opened")
	elevator_opened.emit()
