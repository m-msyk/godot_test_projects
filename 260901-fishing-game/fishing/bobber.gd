class_name Bobber extends RigidBody3D

signal landed(position: Vector3, in_water: bool)
signal retrieved()

const BOB_AMPLITUDE: float = 0.01
const BOB_SPEED: float = 2.5
const WATER_SNAP_TOLERANCE: float = 0.03
const FLOAT_HEIGHT_OFFSET: float = 0.012  # keeps the sphere's body above the surface
const WATER_DRAG: float = 5.5
const SLIDE_STOP_SPEED: float = 0.02
const BASE_SPRITE_PIXEL_SIZE: float = 0.005

@onready var fish_sprite: Sprite3D = $FishSprite
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var _resolved: bool = false
var _floating: bool = false
var _touched_water: bool = false
var _water_surface_y: float = 0.0
var _bob_phase: float = 0.0

func _ready() -> void:
	sleeping_state_changed.connect(_on_sleeping_state_changed)

func launch(start_position: Vector3, initial_velocity: Vector3) -> void:
	freeze = false
	global_position = start_position
	linear_velocity = initial_velocity
	angular_velocity = Vector3.ZERO
	gravity_scale = 1.0
	_resolved = false
	_floating = false
	_touched_water = false
	_bob_phase = 0.0
	sleeping = false

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _resolved:
		return
	var origin := state.transform.origin
	var water := _find_water_at(origin)
	if water == null:
		return
	var surface_y := _surface_height(water, origin)
	if origin.y > surface_y + WATER_SNAP_TOLERANCE:
		return

	if not _touched_water:
		_touched_water = true
		gravity_scale = 0.0
		_water_surface_y = surface_y

	# Pin to the surface (before the solver gets a chance to bounce us off
	# the water's own collision) but let horizontal momentum carry, decaying
	# via drag, instead of stopping dead on contact.
	origin.y = surface_y + FLOAT_HEIGHT_OFFSET
	state.transform.origin = origin
	var vel := state.linear_velocity
	vel.y = 0.0
	vel *= 1.0 - min(WATER_DRAG * state.step, 1.0)
	state.linear_velocity = vel
	state.angular_velocity = Vector3.ZERO

	if vel.length() <= SLIDE_STOP_SPEED:
		_resolved = true
		call_deferred("_start_floating")

func _start_floating() -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	_floating = true
	landed.emit(global_position, true)

func _process(delta: float) -> void:
	if not _floating:
		return
	_bob_phase += delta * BOB_SPEED
	var pos := global_position
	pos.y = _water_surface_y + FLOAT_HEIGHT_OFFSET + (sin(_bob_phase) * 0.5 + 0.5) * BOB_AMPLITUDE
	global_position = pos

func _find_water_at(world_position: Vector3) -> MeshInstance3D:
	for water in get_tree().get_nodes_in_group("water"):
		if not water is MeshInstance3D:
			continue
		var local_pos: Vector3 = water.to_local(world_position)
		var aabb: AABB = water.get_aabb()
		if local_pos.x < aabb.position.x or local_pos.x > aabb.position.x + aabb.size.x:
			continue
		if local_pos.z < aabb.position.z or local_pos.z > aabb.position.z + aabb.size.z:
			continue
		return water
	return null

func _surface_height(water: MeshInstance3D, world_position: Vector3) -> float:
	var local_pos: Vector3 = water.to_local(world_position)
	var aabb: AABB = water.get_aabb()
	var top_local := Vector3(local_pos.x, aabb.position.y + aabb.size.y, local_pos.z)
	return water.to_global(top_local).y

func _on_sleeping_state_changed() -> void:
	if sleeping and not _resolved:
		_resolved = true
		landed.emit(global_position, false)

## Shows the given species' icon in place of the bobber, scaled per-species.
func show_caught_fish(species: FishSpecies) -> void:
	mesh_instance.visible = false
	if species.icon == null:
		return
	fish_sprite.texture = species.icon
	fish_sprite.pixel_size = BASE_SPRITE_PIXEL_SIZE * species.display_scale
	fish_sprite.visible = true

## Stops any physics simulation and glides the bobber to target_position,
## emitting `retrieved` once it arrives. Used both for a plain "reel it back
## in" and for carrying a caught fish up to the player.
func retrieve(target_position: Vector3, duration: float = 0.4) -> void:
	_resolved = true
	_floating = false
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	retrieved.emit()
