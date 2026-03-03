### dialogue_ui.gd

extends Control

@onready var panel = $CanvasLayer/Panel
@onready var dialogue_speaker = $CanvasLayer/Panel/DialogueBox/DialogueSpeaker
@onready var dialogue_text = $CanvasLayer/Panel/DialogueBox/DialogueText
@onready var dialogue_options = $CanvasLayer/Panel/DialogueBox/DialogueOptions

func _ready() -> void:
	panel.visible = false

# Show dialogue box
func show_dialogue(speaker, text, options):
	panel.visible = true
	
	dialogue_speaker.text = speaker
	dialogue_text.text = text
	
	# Remove existing options
	for child in dialogue_options.get_children():
		dialogue_options.remove_child(child)
	
	# Populate options
	for option in options.keys():
		var button = Button.new()
		button.text = option
		
		var font = load("res://fonts/PixelOperator.ttf")
		button.add_theme_font_override("font", font)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_on_option_selected.bind(option))
		dialogue_options.add_child(button)

# Handle response selection
func _on_option_selected(option):
	get_parent().handle_dialogue_choice(option)

# Hide dialogue box
func hide_dialogue():
	panel.visible = false
	Global.player.can_move = true

# Close dialogue
func _on_close_button_pressed() -> void:
	hide_dialogue()
