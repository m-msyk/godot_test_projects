class_name NPC extends CharacterBody3D

@export var npc_name: String
@export var quests: Array[Quest] = []

@onready var dialogic_component: DialogicComponent = $DialogicComponent

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("interactable")
	_connect_signals()

func _connect_signals() -> void:
	dialogic_component.dialogic_signal_received.connect(_on_dialogic_signal)

func start_dialogue() -> void:
	dialogic_component.start_dialogue()

func _on_dialogic_signal(argument: String) -> void:
	var parts = argument.split(":")
	if parts.size() < 1:
		return
	var signal_type = parts[0]
	var signal_value = parts[1] if parts.size() >= 2 else ""
	match signal_type:
		"quest_started":
			_start_quest(signal_value)
		"objective_completed":
			if parts.size() >= 3:
				QuestManager.complete_objective(signal_value, parts[2])
		"floor_unlocked":
			FloorManager.unlock_floor(signal_value)
		"signature_received":
			PlayerData.add_signature(signal_value)
		"save_game":
			if parts.size() >= 4:
				SaveManager.save_game(parts[1], parts[2], parts[3])

func _start_quest(quest_id: String) -> void:
	for quest in quests:
		if quest.quest_id == quest_id:
			QuestManager.add_quest(quest)
			return
