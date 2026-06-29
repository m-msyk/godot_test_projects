@tool
extends MeshInstance3D

func _process(delta):
	var scene_root = owner
	var wall_normal = scene_root.global_transform.basis.z.normalized()
	for i in get_surface_override_material_count():
		var mat = get_surface_override_material(i)
		if mat:
			mat.set_shader_parameter("wall_position", scene_root.global_position)
			mat.set_shader_parameter("wall_normal", wall_normal)
