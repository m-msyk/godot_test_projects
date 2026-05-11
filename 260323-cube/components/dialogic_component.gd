class_name DialogicComponent extends Node

signal dialogic_signal_received(argument: String)

@export var timeline: DialogicTimeline

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)

func start_dialogue() -> void:
	if timeline:
		Dialogic.start(timeline)

func _on_dialogue_started() -> void:
	if Dialogic.current_timeline == timeline:
		StateManager.set_state(StateManager.State.PARTIAL)
		if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
			Dialogic.signal_event.connect(_on_dialogic_signal)

func _on_dialogue_ended() -> void:
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	StateManager.set_state(StateManager.State.FREE)

func _on_dialogic_signal(argument: String) -> void:
	dialogic_signal_received.emit(argument)
