class_name TaskEntry extends VBoxContainer

@onready var quest_name_label: Label = $QuestName

var _description: String

func setup(quest: Quest) -> void:
	quest_name_label.text = quest.quest_name
	_description = quest.quest_description

func get_description() -> String:
	return _description

func set_highlighted(highlighted: bool) -> void:
	quest_name_label.add_theme_color_override("font_color", 
		Color.YELLOW if highlighted else Color.WHITE)
