@tool
class_name CloudShadows
extends Node
## Drifting cloud shadows for an outdoor scene. Add one node to the scene (any
## parent) and every ramp-lit surface (ground, roads, buildings, tufts...) gets
## hard-edged shadow blobs that drift across the world. Leave it out of interior
## scenes: with no CloudShadows node the shadows are off.
##
## It works by switching on the global shader parameters cel_cloud_* (declared in
## Project Settings > Shader Globals, default strength 0) while it is in the tree.
## The shading itself lives in assets/materials/cel_ramp.gdshaderinc.

## How dark the shadow is: 0 = invisible, 1 = the ramp's darkest colour.
@export_range(0.0, 1.0, 0.01) var strength: float = 1.0:
	set(value):
		strength = value
		_apply()
## Rough size of a cloud in metres.
@export_range(2.0, 500.0, 1.0) var cloud_size: float = 20.0:
	set(value):
		cloud_size = value
		_apply()
## Higher = less of the ground in shadow.
@export_range(0.0, 1.0, 0.01) var threshold: float = 0.62:
	set(value):
		threshold = value
		_apply()
## How fast the clouds drift, in metres per second (world x, z).
@export var speed: Vector2 = Vector2(0.8, 0.3):
	set(value):
		speed = value
		_apply()

## How many CloudShadows nodes are in a tree right now. A level swap can add the new
## level's node before the old one leaves, so the shadows only switch off at zero.
static var _active: int = 0

func _enter_tree() -> void:
	_active += 1
	_apply()

func _exit_tree() -> void:
	_active = maxi(_active - 1, 0)
	if _active == 0:
		RenderingServer.global_shader_parameter_set("cel_cloud_strength", 0.0)

func _apply() -> void:
	if not is_inside_tree():
		return
	RenderingServer.global_shader_parameter_set("cel_cloud_strength", strength)
	RenderingServer.global_shader_parameter_set("cel_cloud_scale", 1.0 / maxf(cloud_size, 0.001))
	RenderingServer.global_shader_parameter_set("cel_cloud_threshold", threshold)
	RenderingServer.global_shader_parameter_set("cel_cloud_speed", speed)
