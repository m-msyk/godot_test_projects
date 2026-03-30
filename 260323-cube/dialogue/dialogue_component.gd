class_name DialogueComponent extends Node

@export var npc_id: String
@export var dialogue_resource: Dialogue

var current_state: String = "start"
var current_branch_index: int = 0

func _ready() -> void:
	dialogue_resource.load_from_json("res://dialogue/dialogue_data.json")

func get_current_dialogue() -> Dictionary:
	var branches = dialogue_resource.get_npc_dialogue(npc_id)
	if current_branch_index >= branches.size():
		return {}
	for dialogue in branches[current_branch_index]["dialogues"]:
		if dialogue["state"] == current_state:
			return dialogue
	return {}

func choose(option: String) -> String:
	var dialogue = get_current_dialogue()
	if dialogue.is_empty():
		return "exit"
	var next_state = dialogue["options"].get(option, "exit")
	current_state = next_state
	return next_state

func get_current_branch_id() -> String:
	var branches = dialogue_resource.get_npc_dialogue(npc_id)
	if current_branch_index >= branches.size():
		return ""
	return branches[current_branch_index]["branch_id"]

func advance_branch() -> void:
	current_branch_index += 1
	current_state = "start"
