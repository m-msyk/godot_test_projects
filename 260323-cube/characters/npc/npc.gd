class_name NPC extends CharacterBody3D

@export var npc_name: String
@export var timeline: DialogicTimeline
@export var quests: Array[Quest] = []

func _ready() -> void:
	add_to_group("interactable")
	_connect_signals()

func start_dialogue() -> void:
	Dialogic.start(timeline)

func _connect_signals() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)

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

func _start_quest(quest_id: String) -> void:
	for quest in quests:
		if quest.quest_id == quest_id:
			QuestManager.add_quest(quest)
			return
