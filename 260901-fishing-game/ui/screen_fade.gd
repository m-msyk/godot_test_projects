extends CanvasLayer

var _overlay: ColorRect

func _ready() -> void:
	layer = 128
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

func fade_to_black(duration: float = 0.5) -> void:
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, duration)
	await tween.finished

func fade_from_black(duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, duration)
	await tween.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
