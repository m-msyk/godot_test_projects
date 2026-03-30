extends Node

signal dialogue_advanced(npc_name: String, text: String, options: Dictionary)
signal dialogue_ended

var _current_npc = null

func start(npc) -> void:
	_current_npc = npc
	get_tree().paused = true
	_show_current_state()

func handle_choice(option: String) -> void:
	if _current_npc == null:
		return
	var next_state = _current_npc.dialogue_component.choose(option)
	match next_state:
		"exit":
			end()
		"give_quests":
			_current_npc.quest_component.offer_quests()
			_show_current_state()
		_:
			_show_current_state()

func end() -> void:
	_current_npc = null
	get_tree().paused = false
	dialogue_ended.emit()

func _show_current_state() -> void:
	var dialogue = _current_npc.dialogue_component.get_current_dialogue()
	if dialogue == null:
		end()
		return
	dialogue_advanced.emit(
		_current_npc.npc_name,
		dialogue["text"],
		dialogue["options"]
	)

func is_dialogue_active() -> bool:
	return _current_npc != null
