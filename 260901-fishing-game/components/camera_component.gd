class_name CameraComponent extends Camera3D

@export var rotation_speed: float = 90.0  # degrees per second
@export var orbit_distance: float = 1.5
@export var orbit_height: float = 1.5
@export var menu: MenuComponent

var orbit_angle: float = 0.0

func _ready() -> void:
	_update_camera_transform()
	_connect_signals()

func _connect_signals() -> void:
	menu.sensitivity_changed.connect(_on_sensitivity_changed)

func _on_sensitivity_changed(value: float) -> void:
	rotation_speed = value

func _process(delta: float) -> void:
	if StateManager.current_state == StateManager.State.FREE:
		var rotate_dir := 0.0
		if Input.is_action_pressed("camera_rotate_left"):
			rotate_dir -= 1.0
		if Input.is_action_pressed("camera_rotate_right"):
			rotate_dir += 1.0
		orbit_angle += deg_to_rad(rotate_dir * rotation_speed * delta)
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
