extends Node

signal quest_added(quest: Quest)
signal quest_completed(quest: Quest)
signal objective_updated(quest: Quest)

var active_quests: Dictionary = {}

func add_quest(quest: Quest) -> void:
	if active_quests.has(quest.quest_id):
		return
	quest.state = "in_progress"
	active_quests[quest.quest_id] = quest
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
	active_quests.erase(quest.quest_id)
	quest_completed.emit(quest)

func get_active_quests() -> Array:
	return active_quests.values()
