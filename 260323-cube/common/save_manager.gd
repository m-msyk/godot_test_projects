## Manages save files.

extends Node

const SAVE_PATH := "user://savefile.json"

signal game_reset

func new_game() -> void:
	delete_save()
	WorldState.reset()
	game_reset.emit()

func save_game(save_point_id: String, floor_id: String, area: String) -> void:
	print("Saving game... save_point_id: ", save_point_id, " floor: ", floor_id, " area: ", area)
	var save_data := {
		"meta": {
			"save_point_id": save_point_id,
			"current_floor": floor_id,
			"current_area": area,
			"time_played_seconds": PlayerData.time_played_seconds
		},
		"quest_manager": {
			"active_quests": QuestManager.active_quests.keys(),
			"completed_quests": QuestManager.completed_quests.keys()
		},
		"floor_manager": {
			"unlocked_floors": FloorManager.unlocked_floors
		},
		"player_data": {
			"signatures": PlayerData.signatures,
			"signature_givers": PlayerData.signature_givers,
			"rhythm_points": PlayerData.rhythm_points,
			"note_offset": PlayerData.note_offset,
			"upgrades": PlayerData.upgrades
		},
		"world_state": {
			"flags": WorldState.flags
		}
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	Dialogic.Save.save("slot_0")
	print("Save complete. File exists: ", save_exists())

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> void:
	print("Loading game...")
	if not save_exists():
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var save_data: Dictionary = JSON.parse_string(json_string)

	# Restore QuestManager
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	for quest_id in save_data["quest_manager"]["active_quests"]:
		var quest = _find_quest_resource(quest_id)
		if quest:
			QuestManager.active_quests[quest_id] = quest
	for quest_id in save_data["quest_manager"]["completed_quests"]:
		var quest = _find_quest_resource(quest_id)
		if quest:
			QuestManager.completed_quests[quest_id] = quest

	# Restore FloorManager
	FloorManager.unlocked_floors.clear()
	for floor_id in save_data["floor_manager"]["unlocked_floors"]:
		FloorManager.unlocked_floors.append(floor_id)
	FloorManager.current_floor = save_data["meta"]["current_floor"].to_lower()

	# Restore PlayerData
	PlayerData.signatures = save_data["player_data"]["signatures"]
	PlayerData.signature_givers.clear()
	for giver_id in save_data["player_data"]["signature_givers"]:
		PlayerData.signature_givers.append(giver_id)
	PlayerData.time_played_seconds = save_data["meta"]["time_played_seconds"]
	PlayerData.rhythm_points = save_data["player_data"].get("rhythm_points", 0)
	PlayerData.note_offset = save_data["player_data"].get("note_offset", 0.25)
	var saved_upgrades: Dictionary = save_data["player_data"].get("upgrades", {})
	for key in saved_upgrades:
		PlayerData.upgrades[key] = saved_upgrades[key]

	# Restore WorldState
	var saved_flags: Dictionary = save_data.get("world_state", {}).get("flags", {})
	for flag_id in saved_flags:
		WorldState.flags[flag_id] = saved_flags[flag_id]

	# Restore Dialogic variables
	Dialogic.Save.load("slot_0")

	print("Load complete. Current floor: ", FloorManager.current_floor)
	print("Active quests: ", QuestManager.active_quests.keys())
	print("Signatures: ", PlayerData.signatures)
	print("Rhythm points: ", PlayerData.rhythm_points)
	print("World flags: ", WorldState.flags)

func _find_quest_resource(quest_id: String) -> Quest:
	var dir := DirAccess.open("res://quests/")
	if dir == null:
		return null
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var quest = load("res://quests/" + file_name)
			if quest is Quest and quest.quest_id == quest_id:
				dir.list_dir_begin()
				return quest
		file_name = dir.get_next()
	return null

func get_save_meta() -> Dictionary:
	if not save_exists():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()
	return JSON.parse_string(json_string)["meta"]

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	Dialogic.Save.delete_slot("slot_0")
