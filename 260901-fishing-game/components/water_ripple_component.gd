class_name WaterRippleComponent extends Node

const MAX_RIPPLES := 8

@export var footsteps: FootstepsComponent

var _origins: PackedVector2Array = PackedVector2Array()
var _start_times: PackedFloat32Array = PackedFloat32Array()
var _next_index := 0
var _elapsed := 0.0

func _ready() -> void:
	_origins.resize(MAX_RIPPLES)
	_start_times.resize(MAX_RIPPLES)
	for i in MAX_RIPPLES:
		_start_times[i] = -1000.0

	if footsteps:
		footsteps.footstep_played.connect(_on_footstep_played)

func tick(delta: float) -> void:
	_elapsed += delta
	for water in get_tree().get_nodes_in_group("water"):
		if water is MeshInstance3D:
			var material := water.get_active_material(0) as ShaderMaterial
			if material:
				material.set_shader_parameter("game_time", _elapsed)

func _on_footstep_played(global_pos: Vector3) -> void:
	for water in get_tree().get_nodes_in_group("water"):
		if water is MeshInstance3D:
			var material := water.get_active_material(0) as ShaderMaterial
			if material:
				# world-space water (imported from Blender) measures ripples in metres; the lobby pool in local units
				var local_pos = water.to_local(global_pos)
				var in_world: bool = material.get_shader_parameter("world_space") == true
				_origins[_next_index] = Vector2(global_pos.x, global_pos.z) if in_world else Vector2(local_pos.x, local_pos.z)
				_start_times[_next_index] = _elapsed
				material.set_shader_parameter("ripple_origins", _origins)
				material.set_shader_parameter("ripple_start_times", _start_times)

	_next_index = (_next_index + 1) % MAX_RIPPLES
