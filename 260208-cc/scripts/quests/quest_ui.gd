### quest_ui.gd

extends Control

@onready var panel: Panel = $CanvasLayer/Panel
@onready var quest_list: VBoxContainer = $CanvasLayer/Panel/Contents/Details/QuestList
@onready var quest_title: Label = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestTitle
@onready var quest_description: Label = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestDescription
@onready var quest_objectives: VBoxContainer = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestObjectives
@onready var quest_rewards: VBoxContainer = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestRewards

var selected_quest: Quest = null

func _ready():
	panel.visible = false

# Show/hide quest log
func show_hide_log():
	panel.visible = !panel.visible

# Populate quest list
func update_quest_list():
	# Remove all items
	for child in quest_list.get_children():
		quest_list.remove_child(child)
	
	# Populate with new items
	var active_quests = get_parent().get_active_quests()
	if active_quests.size():
		clear_quest_details()
		# Global.player.selected_quest = null
		# Global.player.update_quest_tracker(null)
	else:
		for quest in active_quests:
			var button = Button.new()
			var font = load("res://fonts/PixelOperator.ttf")
			button.add_theme_font_override("font", font)
			button.add_theme_font_size_override("font_size", 16)
			button.pressed.connect(_on_quest_selected.bind(quest))
			quest_list.add_child(button)

func _on_quest_selected(quest: Quest):
	selected_quest = quest
	# Populate details
	quest_title.text = quest.quest_name
	quest_description.text = quest.quest_description
	
	# Populate objectives
	for child in quest_objectives.get_children():
		quest_objectives.remove_child(child)
	
	for objective in quest.objectives:
		var label = Label.new()
		var font = load("res://fonts/PixelOperator.ttf")
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 16)
		
		if objective.target_type == "collection":
			label.text = objective.description + "(" + str(objective.collected_quantity) + "/" + str(objective.required_quantity) + ")"
		else:
			label.text = objective.description
		
		var completed_color = Color(0.62, 0.912, 0.643, 1.0)
		var incompleted_color = Color(0.848, 0.362, 0.249, 1.0)
		if objective.is_completed:
			label.add_theme_color_override("font_color", completed_color)
		else:
			label.add_theme_color_override("font_color", incompleted_color)
		
		quest_objectives.add_child(label)
		
	# Populate rewards
	for child in quest_rewards.get_children():
		quest_rewards.remove_child(child)
	
	for reward in quest.rewards:
		var label = Label.new()
		var font = load("res://fonts/PixelOperator.ttf")
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0,0.84,0))
		label.text = "Rewards: " + reward.reward_type.capitalize() + ": " + str(reward.reward_amount)
		quest_rewards.add_child(label)
		
# Trigger to clear quest details
func clear_quest_details():
	quest_title.text = ""
	quest_description.text = ""
	
	for child in quest_objectives.get_children():
		quest_objectives.remove_child(child)
		
	for child in quest_rewards.get_children():
		quest_rewards.remove_child(child)
		
		
		
		
