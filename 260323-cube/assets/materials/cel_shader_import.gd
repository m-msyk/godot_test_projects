@tool
extends EditorScenePostImport

func _post_import(scene: Node) -> Object:
	_apply_cel_shader(scene)
	return scene

func _apply_cel_shader(node: Node) -> void:
	if node is MeshInstance3D:
		for i in node.get_surface_override_material_count():
			var mat = node.mesh.surface_get_material(i)
			if mat:
				var cel_mat = ShaderMaterial.new()
				cel_mat.shader = load("res://assets/materials/cel_shader.gdshader")
				# Preserve the existing albedo color from the Blender material
				if mat is StandardMaterial3D:
					cel_mat.set_shader_parameter("albedo", mat.albedo_color)
					cel_mat.set_shader_parameter("texture_albedo", mat.albedo_texture)
				# Set your defaults
				cel_mat.set_shader_parameter("shading_steps", 2.0)
				cel_mat.set_shader_parameter("shadow_softness", 0.05)
				cel_mat.set_shader_parameter("ambient_light", 0.25)
				node.set_surface_override_material(i, cel_mat)
	for child in node.get_children():
		_apply_cel_shader(child)
