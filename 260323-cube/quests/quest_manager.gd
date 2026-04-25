extends Node

signal quest_added(quest: Quest)
signal quest_started(quest: Quest)
signal quest_completed(quest: Quest)
signal objective_updated(quest: Quest)

var active_quests: Dictionary = {}
var completed_quests: Dictionary = {}

func add_quest(quest: Quest) -> void:
	if active_quests.has(quest.quest_id):
		return
	if completed_quests.has(quest.quest_id):
		return
	quest.state = "in_progress"
	active_quests[quest.quest_id] = quest
	print("active_quests: ", active_quests.keys())
	quest_added.emit(quest)

func complete_objective(quest_id: String, objective_id: String) -> void:
	var quest = active_quests.get(quest_id, null)
	if quest == null:
		return
	quest.complete_objective(objective_id)
	objective_updated.emit(quest)
	if quest.is_completed():
		_complete_quest(quest)

func _complete_quest(quest: Quest) -> void:
	completed_quests[quest.quest_id] = quest
	active_quests.erase(quest.quest_id)
	print("completed_quests: ", completed_quests.keys())
	quest_completed.emit(quest)

func get_active_quests() -> Array:
	return active_quests.values()

func is_quest_not_started(quest_id: String) -> bool:
	return not active_quests.has(quest_id) \
	and not completed_quests.has(quest_id)

func is_quest_in_progress(quest_id: String) -> bool:
	return active_quests.has(quest_id)

func is_quest_completed(quest_id: String) -> bool:
	return completed_quests.has(quest_id)
