class_name MovementComponent extends Node

@export var body: CharacterBody3D
@export var model: Node3D
@export var speed := 8.0
@export var jump_velocity := 12.0
@export var gravity_multiplier := 3.0

var direction: Vector2 = Vector2.ZERO
var wants_jump := false

func tick(delta: float) -> void:
	if body == null:
		return
	
	# Top down movement
	body.velocity.x = direction.x * speed
	body.velocity.z = direction.y * speed
	
	# Gravity
	if not body.is_on_floor():
		body.velocity += body.get_gravity() * delta * gravity_multiplier
	
	# Jump
	if wants_jump and body.is_on_floor():
		body.velocity.y = jump_velocity
	wants_jump = false
	
	body.move_and_slide()
	
	# Face movement direction
	if model and direction.length_squared() > 0.001:
		var look_dir := Vector3(-direction.x, 0.0, -direction.y).normalized()
		model.look_at(model.global_position + look_dir, Vector3.UP)
