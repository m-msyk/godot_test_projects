extends Node

const BASE_CURSOR := preload("res://assets/ui/cursor.png")
var _current_scale := 3
var _real_cursor: ImageTexture

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_cursor_for_scale(_current_scale)

func _input(event: InputEvent) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
		if event is InputEventMouseMotion:
			if (event as InputEventMouseMotion).relative != Vector2.ZERO:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func set_cursor_for_scale(scale: int) -> void:
	_current_scale = scale
	var img := BASE_CURSOR.get_image()
	var base_size := img.get_size()
	img.resize(base_size.x * scale, base_size.y * scale, Image.INTERPOLATE_NEAREST)
	_real_cursor = ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(_real_cursor)
