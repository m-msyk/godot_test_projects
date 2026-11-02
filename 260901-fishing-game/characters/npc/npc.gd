class_name NPC extends CharacterBody3D

signal battle_requested(npc: NPC)
signal battle_scene_end_requested()

@export var npc_name: String
@export var quests: Array[Quest] = []
@export var battle_beatmap_path: String = ""
@export var timeline_01: DialogicTimeline
@export var timeline_battle_end: DialogicTimeline

@onready var dialogic_component: DialogicComponent = $DialogicComponent

var _is_active: bool = false
var _pending_battle: bool = false
var _pending_battle_scene_end: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("interactable")
	_connect_signals()

func _connect_signals() -> void:
	dialogic_component.dialogic_signal_received.connect(_on_dialogic_signal)
	dialogic_component.dialogue_ended.connect(_on_dialogue_ended)

func _get_current_timeline() -> DialogicTimeline:
	return timeline_01

func start_dialogue() -> void:
	_is_active = true
	dialogic_component.timeline = _get_current_timeline()
	StateManager.set_state(StateManager.State.PARTIAL)
	dialogic_component.start_dialogue()

func start_battle_outcome_dialogue(outcome: String) -> void:
	_is_active = true
	Dialogic.VAR.battle_outcome = outcome
	dialogic_component.timeline = timeline_battle_end
	StateManager.set_state(StateManager.State.PARTIAL)
	dialogic_component.start_dialogue()

func _on_dialogue_ended() -> void:
	if not _is_active:
		return
	_is_active = false
	dialogic_component.timeline = _get_current_timeline()
	StateManager.set_state(StateManager.State.FREE)
	if _pending_battle:
		_pending_battle = false
		battle_requested.emit(self)
	if _pending_battle_scene_end:
		_pending_battle_scene_end = false
		battle_scene_end_requested.emit()

func _on_dialogic_signal(argument: String) -> void:
	var parts := argument.split(":")
	if parts.size() < 1:
		return
	var signal_type := parts[0]
	var signal_value := parts[1] if parts.size() >= 2 else ""
	match signal_type:
		"quest_started":
			_start_quest(signal_value)
		"objective_completed":
			if parts.size() >= 3:
				QuestManager.complete_objective(signal_value, parts[2])
		"floor_unlocked":
			FloorManager.unlock_floor(signal_value)
		"fish_caught":
			PlayerData.catch_fish(signal_value)
		"set_flag":
			WorldState.set_flag(signal_value)
		"battle_accepted":
			Dialogic.VAR.battle_outcome = ""
			_pending_battle = true
		"battle_scene_end":
			_pending_battle_scene_end = true

func _start_quest(quest_id: String) -> void:
	for quest in quests:
		if quest.quest_id == quest_id:
			QuestManager.add_quest(quest)
			return
