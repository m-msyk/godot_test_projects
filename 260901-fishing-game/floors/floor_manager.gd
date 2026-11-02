extends Node

signal floor_unlocked(floor_id: String)

var unlocked_floors: Array[String] = ["b1"]
var current_floor: String = "b1"

const FLOOR_SCENES: Dictionary = {
	"b1": "b1_lobby",
	"b2": "b2_lobby",
	"b3": "b3_server",
}

func _ready() -> void:
	SaveManager.game_reset.connect(reset)

func unlock_floor(floor_id: String) -> void:
	print("unlock_floor called: ", floor_id)
	if not unlocked_floors.has(floor_id):
		unlocked_floors.append(floor_id)
		floor_unlocked.emit(floor_id)

func is_floor_unlocked(floor_id: String) -> bool:
	return unlocked_floors.has(floor_id)

func set_current_floor(floor_id: String) -> void:
	current_floor = floor_id

func get_current_scene() -> String:
	return FLOOR_SCENES.get(current_floor, "b1_lobby")

func get_unlocked_floors() -> Array[String]:
	return unlocked_floors

func reset() -> void:
	unlocked_floors = ["b1"]
	current_floor = "b1"
