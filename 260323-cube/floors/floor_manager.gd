extends Node

signal floor_unlocked(floor_id: String)

var unlocked_floors: Array[String] = ["b1"]
var current_floor: String = "b1"

func unlock_floor(floor_id: String) -> void:
	if not unlocked_floors.has(floor_id):
		unlocked_floors.append(floor_id)
		floor_unlocked.emit(floor_id)

func is_floor_unlocked(floor_id: String) -> bool:
	return unlocked_floors.has(floor_id)

func set_current_floor(floor_id: String) -> void:
	current_floor = floor_id

func get_unlocked_floors() -> Array[String]:
	return unlocked_floors
