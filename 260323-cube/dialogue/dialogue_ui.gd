class_name DialogueUI extends Control

@onready var speaker_label: Label = $PanelContainer/DialogueBox/SpeakerLabel
@onready var dialogue_text: Label = $PanelContainer/DialogueBox/DialogueText
@onready var options_container: HBoxContainer = $PanelContainer/DialogueBox/OptionsContainer

var _current_options: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_connect_signals()

func _connect_signals() -> void:
	DialogueManager.dialogue_advanced.connect(_on_dialogue_advanced)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") and _current_options.is_empty():
		DialogueManager.end()

func _on_dialogue_advanced(npc_name: String, text: String, options: Dictionary) -> void:
	speaker_label.text = npc_name
	dialogue_text.text = text
	_current_options = options
	_populate_options(options)
	show()

func _on_dialogue_ended() -> void:
	hide()

func _populate_options(options: Dictionary) -> void:
	for child in options_container.get_children():
		child.queue_free()
	
	var buttons: Array = []
	for option_text in options.keys():
		var button := Button.new()
		button.text = option_text
		
# Remove border, add yellow hover
		var empty := StyleBoxEmpty.new()
		button.add_theme_stylebox_override("normal", empty)
		button.add_theme_stylebox_override("hover", empty)
		button.add_theme_stylebox_override("pressed", empty)
		button.add_theme_stylebox_override("focus", empty)
		button.add_theme_color_override("font_hover_color", Color.YELLOW)
		button.add_theme_color_override("font_focus_color", Color.YELLOW)
		
		button.pressed.connect(DialogueManager.handle_choice.bind(option_text))
		options_container.add_child(button)
		buttons.append(button)
	
	if buttons.is_empty():
		return
	
	# Set up focus neighbors so arrow keys cycle between buttons
	for i in buttons.size():
		var prev = buttons[(i - 1 + buttons.size()) % buttons.size()]
		var next = buttons[(i + 1) % buttons.size()]
		buttons[i].focus_neighbor_left = prev.get_path()
		buttons[i].focus_neighbor_right = next.get_path()
	
	# Give focus to the first button automatically
	buttons[0].grab_focus()
