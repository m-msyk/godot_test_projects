class_name OcclusionRevealComponent extends Node
## "Occlusion see-through" (a.k.a. x-ray cutout / peephole reveal): when something
## completely hides the player from the camera, wait a moment, then open a circular
## hole that grows from the player's centre until the player is visible again.
##
## How it works:
##  * Visibility test: every physics frame, rays go from the camera to several points on
##    the player's body. If every one of them is blocked, the player is completely hidden.
##  * The test needs something to hit. Leaves and other scenery usually have no
##    collision, so when the level loads this builds invisible "occluder" shapes from
##    the visible meshes on physics layer 20 (nothing collides with it; only these rays
##    look at it).
##  * The hole: the global shader parameters cel_reveal_radius / cel_reveal_center
##    are driven here, and the cel shaders (cel_reveal.gdshaderinc) discard everything
##    inside that circle that stands between the camera and the player.

## physics layer 20 ("occluders")
const OCCLUDER_LAYER := 1 << 19

@export var camera: Camera3D
## The player's root; its origin is at the feet.
@export var body: Node3D
## Seconds the player must be completely hidden before the hole opens.
@export var hide_delay: float = 0.2
@export var open_time: float = 0.25
@export var close_time: float = 0.2
## Seconds the player must be fully visible again before the hole closes.
@export var clear_delay: float = 0.15
## Radius of the hole in metres, measured at the player's distance from the camera
## (the hole is a cone, so it looks this size on screen at any depth). The player is
## 1.8 m tall; this leaves a visible margin around them.
@export var reveal_radius: float = 2.2
@export var body_height: float = 1.8
@export var body_radius: float = 0.45
## Meshes in these groups don't block the view (water, etc.).
@export var ignore_groups: Array[StringName] = [&"water"]

var _open: float = 0.0 # 0 = closed, 1 = fully open
var _revealing: bool = false
var _hidden_time: float = 0.0
var _clear_time: float = 0.0

func _ready() -> void:
	_build_occluders.call_deferred()

func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set("cel_reveal_radius", 0.0)

func _physics_process(delta: float) -> void:
	if camera == null or body == null:
		return
	var blocked := _count_blocked_points()
	var total := 5
	if not _revealing:
		_hidden_time = _hidden_time + delta if blocked == total else 0.0
		if _hidden_time >= hide_delay:
			_revealing = true
			_clear_time = 0.0
	else:
		# stay open while any part of the player is still behind something
		_clear_time = _clear_time + delta if blocked == 0 else 0.0
		if _clear_time >= clear_delay:
			_revealing = false
			_hidden_time = 0.0

	var duration := open_time if _revealing else close_time
	_open = move_toward(_open, 1.0 if _revealing else 0.0, delta / maxf(duration, 0.001))
	var eased := 1.0 - pow(1.0 - _open, 3.0) # fast at first, settling at the edge
	RenderingServer.global_shader_parameter_set("cel_reveal_radius", reveal_radius * eased)
	RenderingServer.global_shader_parameter_set("cel_reveal_center", body.global_position + Vector3(0.0, body_height * 0.5, 0.0))

## How many of the five body points the camera cannot see (0 = fully visible, 5 = hidden).
func _count_blocked_points() -> int:
	var cam_pos := camera.global_position
	var right := camera.global_basis.x
	var base := body.global_position
	var points := [
		base + Vector3(0.0, body_height * 0.5, 0.0), # centre
		base + Vector3(0.0, body_height * 0.92, 0.0), # head
		base + Vector3(0.0, 0.2, 0.0), # feet
		base + Vector3(0.0, body_height * 0.5, 0.0) + right * body_radius * 0.9, # sides
		base + Vector3(0.0, body_height * 0.5, 0.0) - right * body_radius * 0.9,
	]
	var space := body.get_world_3d().direct_space_state
	var blocked := 0
	for target: Vector3 in points:
		var query := PhysicsRayQueryParameters3D.create(cam_pos, target, OCCLUDER_LAYER)
		var hit := space.intersect_ray(query)
		# a hit right at the target is the ground or the player's own spot, not an occluder
		if not hit.is_empty() and cam_pos.distance_to(hit.position) < cam_pos.distance_to(target) - 0.35:
			blocked += 1
	return blocked

## Gives every mesh in the level an invisible collision copy on the occluder layer.
func _build_occluders() -> void:
	if body == null:
		return
	var root: Node = body.owner if body.owner != null else body.get_parent()
	var shapes := {} # Mesh -> ConcavePolygonShape3D, shared between copies of the same mesh
	var count := 0
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		if mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			continue
		if _is_ignored(mi):
			continue
		if not shapes.has(mi.mesh):
			shapes[mi.mesh] = mi.mesh.create_trimesh_shape()
		var shape: Shape3D = shapes[mi.mesh]
		if shape == null:
			continue
		var occluder := StaticBody3D.new()
		occluder.name = "Occluder"
		occluder.collision_layer = OCCLUDER_LAYER
		occluder.collision_mask = 0
		var collision := CollisionShape3D.new()
		collision.shape = shape
		occluder.add_child(collision)
		mi.add_child(occluder)
		count += 1
	print("OcclusionReveal: %d occluders from %d unique meshes" % [count, shapes.size()])

## Skip characters (the player, NPCs), anything physics-driven, and ignored groups.
func _is_ignored(mi: Node) -> bool:
	for group in ignore_groups:
		if mi.is_in_group(group):
			return true
	var parent := mi.get_parent()
	while parent != null:
		if parent is CharacterBody3D or parent is RigidBody3D:
			return true
		parent = parent.get_parent()
	return false
