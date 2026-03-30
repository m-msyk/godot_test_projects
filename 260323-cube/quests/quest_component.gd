class_name QuestComponent extends Node

@export var quests: Array[Quest] = []

func offer_quests() -> void:
	var branch_id = _get_parent_branch_id()
	for quest in quests:
		if quest.unlock_id == branch_id and quest.state == "not_started":
			QuestManager.add_quest(quest)

func all_quests_completed_for_current_branch() -> bool:
	var branch_id = _get_parent_branch_id()
	for quest in quests:
		if quest.unlock_id == branch_id and quest.state != "completed":
			return false
	return true

func _get_parent_branch_id() -> String:
	var dialogue_component = get_parent().get_node("DialogueComponent")
	if dialogue_component:
		return dialogue_component.get_current_branch_id()
	return ""
