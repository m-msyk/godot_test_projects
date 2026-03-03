### dialogue_manager.gd

extends Node2D

@onready var dialogue_ui: Control = $DialogueUI

var npc: Node = null

# Show dialogue with data
func show_dialogue(npc):
	check_and_advance_branch()
	
	var quest_dialogue = npc.get_quest_dialogue()
	if quest_dialogue["text"] != "":
		dialogue_ui.show_dialogue(npc.npc_name, quest_dialogue["text"], quest_dialogue["options"])
	else:
		var dialogue = npc.get_current_dialogue()
		if dialogue:
			dialogue_ui.show_dialogue(npc.npc_name, dialogue["text"], dialogue["options"])

# Hide dialogue
func hide_dialogue():
	dialogue_ui.hide_dialogue()

# Dialogue state management
func handle_dialogue_choice(option):
	# Get current dialogue branch
	var current_dialogue = npc.get_current_dialogue()
	if not current_dialogue:
		return
	
	# Update state
	var next_state = current_dialogue["options"].get(option, "start")
	npc.set_dialogue_state(next_state)
	
	# Handle state transitions
	if next_state == "end":
		if all_quests_completed_for_branch(npc.current_branch_index):
			advance_to_next_branch()
		else:
			dialogue_ui.show_dialogue(npc.npc_name, "Goodbye for now.", {"Okay": "Exit"})
	elif next_state == "exit":
		npc.set_dialogue_state("start")
		hide_dialogue()
	elif next_state == "give_quests":
		offer_quests(npc.dialogue_resource.get_npc_dialogue(npc.npc_id)[npc.current_branch_index]["branch_id"])
		show_dialogue(npc)
	else:
		show_dialogue(npc)

func all_quests_completed_for_branch(branch_index):
	var branch_id = npc.dialogue_resource.get_npc_dialogue(npc.npc_id)[branch_index]["branch_id"]
	for quest in npc.quests:
		if quest.unlock_id == branch_id and quest.state != "completed":
			return false
	return true

# At branch, offer all currently available quests
func offer_quests(branch_id: String):
		for quest in npc.quests:
			if quest.unlock_id == branch_id and quest.state == "not_started":
				npc.offer_quest(quest.quest_id)

# At default branch, offer all previously unaccepted quests
func offer_remaining_quests():
	for quest in npc.quests:
		if quest.state == "not_started":
			npc.offer_quest(quest.quest_id)

func check_and_advance_branch():
	if all_quests_completed_for_branch(npc.current_branch_index) and npc.current_branch_index < npc.dialogue_resource.get_npc_dialogue(npc.npc_id).size() - 1:
		advance_to_next_branch()

func advance_to_next_branch():
	npc.set_dialogue_branch(npc.current_branch_index + 1)
	npc.set_dialogue_state("start")
	show_dialogue(npc)
