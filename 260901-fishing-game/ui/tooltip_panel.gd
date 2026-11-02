class_name TooltipPanel extends PanelContainer

@onready var tooltip_label: Label = $TooltipLabel

func _ready() -> void:
	visible = false

func show_tooltip(text: String, at_position: Vector2) -> void:
	tooltip_label.text = text
	self.position = at_position
	visible = true

func hide_tooltip() -> void:
	visible = false
