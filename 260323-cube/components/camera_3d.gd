extends Camera3D

@export var rotation_speed: float = 0.3
@export var orbit_distance: float = 10.0
@export var orbit_height: float = 10.0

var orbit_angle: float = 0.0
var input: InputComponent
var menu: MenuComponent

func _ready() -> void:
	input = get_parent().get_node("%InputComponent")
	menu = get_parent().get_node("%MenuComponent")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_update_camera_transform()
	_connect_signals()

func _connect_signals() -> void:
	menu.sensitivity_changed.connect(_on_sensitivity_changed)

func _on_sensitivity_changed(value: float) -> void:
	rotation_speed = value

func _process(_delta: float) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		orbit_angle += deg_to_rad(input.mouse_delta.x * rotation_speed)
	_update_camera_transform()

func _update_camera_transform() -> void:
	var player: Node3D = get_parent()
	var offset := Vector3(
		sin(orbit_angle) * orbit_distance,
		orbit_height,
		cos(orbit_angle) * orbit_distance
	)
	global_position = player.global_position + offset
	look_at(player.global_position, Vector3.UP)
