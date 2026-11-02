class_name FishingComponent extends Node

signal bobber_cast()
signal bobber_landed()
signal bobber_reset()
signal fish_hooked(species: FishSpecies)

const BOBBER_SCENE = preload("res://fishing/bobber.tscn")
const CATCH_DIALOGUE_TIMELINE = preload("res://dialogue/fish_caught.dtl")

enum State { IDLE, CASTING, WAITING, HOOKED, BATTLING, RETRIEVING }

const HOLD_FORWARD_DISTANCE: float = 0.09
const HOLD_HEIGHT: float = 0.13

@export var body: CharacterBody3D
@export var model: Node3D
@export var fishing_line: FishingLine
@export var interaction_component: InteractionComponent
@export var dialogic_component: DialogicComponent
@export var throw_horizontal_speed: float = 0.4
@export var throw_vertical_speed: float = 0.5
@export var cast_forward_offset: float = 0.1
@export var cast_height_offset: float = 0.15
@export var max_bobber_distance: float = 0.6
@export var min_bite_wait: float = 2.0
@export var max_bite_wait: float = 10.0
@export var hook_reaction_window: float = 2.0
@export var retrieve_duration: float = 0.4
@export var catch_turn_duration: float = 0.4

var state: State = State.IDLE
var _bobber: Bobber = null
var _bite_timer: float = 0.0
var _hook_timer: float = 0.0
var _hooked_species: FishSpecies = null
var _held_bobber: Bobber = null

func _input(event: InputEvent) -> void:
	if StateManager.current_state != StateManager.State.FREE:
		return
	if event.is_action_pressed("fish"):
		_on_fish_pressed()

func tick(delta: float) -> void:
	if _held_bobber and is_instance_valid(_held_bobber):
		_held_bobber.global_position = _get_hold_position()
	match state:
		State.WAITING:
			if _bobber == null or body == null:
				return
			if body.global_position.distance_to(_bobber.global_position) > max_bobber_distance:
				_reset()
				return
			if _bite_timer > 0.0:
				_bite_timer -= delta
				if _bite_timer <= 0.0:
					_hook_fish()
		State.HOOKED:
			_hook_timer -= delta
			if _hook_timer <= 0.0:
				_fish_escaped()

func _on_fish_pressed() -> void:
	match state:
		State.IDLE:
			if interaction_component and interaction_component.find_interactable() != null:
				return
			_cast()
		State.CASTING, State.WAITING:
			_reset()
		State.HOOKED:
			_trigger_battle()

func _cast() -> void:
	var facing := -model.global_basis.z
	facing.y = 0.0
	facing = facing.normalized()

	var start_position := body.global_position + facing * cast_forward_offset + Vector3.UP * cast_height_offset
	var launch_velocity := facing * throw_horizontal_speed + Vector3.UP * throw_vertical_speed

	_bobber = BOBBER_SCENE.instantiate()
	body.get_parent().add_child(_bobber)
	_bobber.add_collision_exception_with(body)
	_bobber.landed.connect(_on_bobber_landed)
	_bobber.launch(start_position, launch_velocity)
	if fishing_line:
		fishing_line.set_target(_bobber)

	state = State.CASTING
	bobber_cast.emit()

func _on_bobber_landed(_position: Vector3, in_water: bool) -> void:
	state = State.WAITING
	_bite_timer = randf_range(min_bite_wait, max_bite_wait) if in_water else 0.0
	bobber_landed.emit()

func _hook_fish() -> void:
	var species := PlayerData.pick_random_fish()
	if species == null:
		return
	_hooked_species = species
	state = State.HOOKED
	_hook_timer = hook_reaction_window
	if fishing_line:
		fishing_line.set_taut(true)

func _trigger_battle() -> void:
	var species := _hooked_species
	_hooked_species = null
	state = State.BATTLING
	fish_hooked.emit(species)

func _fish_escaped() -> void:
	_hooked_species = null
	_reset()

## Called by Main once a fish-catch battle resolves. On a win, plays the
## "hold the fish up" celebration before returning control; otherwise just
## reels the bobber back in normally.
func finish_battle(caught: bool = false, species: FishSpecies = null) -> void:
	if caught and species and _bobber:
		_catch_sequence(species)
	else:
		_reset()

func _catch_sequence(species: FishSpecies) -> void:
	state = State.RETRIEVING
	var bobber_to_retrieve := _bobber
	_bobber = null

	StateManager.set_state(StateManager.State.PARTIAL)

	bobber_to_retrieve.show_caught_fish(species)
	bobber_to_retrieve.retrieve(_get_hold_position(), retrieve_duration)
	await bobber_to_retrieve.retrieved
	if fishing_line:
		fishing_line.clear_target()

	# Recomputed every frame from the player's own origin + current facing,
	# rather than parented under a fixed marker, so it stays in front no
	# matter how the model rotates during the celebration.
	_held_bobber = bobber_to_retrieve

	var original_quat := model.global_transform.basis.get_rotation_quaternion()
	await _face_camera(catch_turn_duration)

	if dialogic_component and CATCH_DIALOGUE_TIMELINE:
		Dialogic.VAR.caught_fish_name = species.display_name
		dialogic_component.timeline = CATCH_DIALOGUE_TIMELINE
		dialogic_component.start_dialogue()
		await dialogic_component.dialogue_ended

	await _tween_facing(original_quat, catch_turn_duration)

	_held_bobber = null
	bobber_to_retrieve.queue_free()
	state = State.IDLE
	StateManager.set_state(StateManager.State.FREE)
	bobber_reset.emit()

func _get_hold_position() -> Vector3:
	var facing := -model.global_basis.z
	facing.y = 0.0
	facing = facing.normalized()
	return body.global_position + facing * HOLD_FORWARD_DISTANCE + Vector3.UP * HOLD_HEIGHT

func _face_camera(duration: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or model == null:
		return
	var to_camera := camera.global_position - model.global_position
	to_camera.y = 0.0
	if to_camera.length_squared() < 0.0001:
		return
	var target_transform := model.global_transform.looking_at(model.global_position + to_camera, Vector3.UP)
	await _tween_facing(target_transform.basis.get_rotation_quaternion(), duration)

func _tween_facing(target_quat: Quaternion, duration: float) -> void:
	if model == null:
		return
	var start_quat := model.global_transform.basis.get_rotation_quaternion()
	var tween := create_tween()
	tween.tween_method(
		func(t: float): model.global_transform.basis = Basis(start_quat.slerp(target_quat, t)),
		0.0, 1.0, duration
	)
	await tween.finished

func _reset() -> void:
	_hooked_species = null
	_bite_timer = 0.0
	_hook_timer = 0.0
	if _bobber == null:
		state = State.IDLE
		bobber_reset.emit()
		return

	state = State.RETRIEVING
	var bobber_to_retrieve := _bobber
	_bobber = null
	var target := fishing_line.get_start_position() if fishing_line else body.global_position
	bobber_to_retrieve.retrieve(target, retrieve_duration)
	await bobber_to_retrieve.retrieved
	if fishing_line:
		fishing_line.clear_target()
	bobber_to_retrieve.queue_free()
	state = State.IDLE
	bobber_reset.emit()
