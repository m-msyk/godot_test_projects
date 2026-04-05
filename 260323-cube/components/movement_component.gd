class_name MovementComponent extends Node

@export var body: CharacterBody3D
@export var model: Node3D
@export var speed := 1.0
@export var jump_velocity := 3.0
@export var gravity_multiplier := 1.0
var direction: Vector2 = Vector2.ZERO
var wants_jump := false

func tick(delta: float, camera_angle: float = 0.0) -> void:
	if body == null:
		return

	# Rotate input direction to match camera facing
	var rotated_dir := direction.rotated(-camera_angle)

	# Movement relative to camera
	body.velocity.x = rotated_dir.x * speed
	body.velocity.z = rotated_dir.y * speed

	# Gravity
	if not body.is_on_floor():
		body.velocity += body.get_gravity() * delta * gravity_multiplier

	# Jump
	if wants_jump and body.is_on_floor():
		body.velocity.y = jump_velocity
	wants_jump = false

	body.move_and_slide()

	# Face movement direction
	if model and rotated_dir.length_squared() > 0.001:
		var look_dir := Vector3(rotated_dir.x, 0.0, rotated_dir.y).normalized()
		model.look_at(model.global_position + look_dir, Vector3.UP)
