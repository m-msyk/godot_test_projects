@tool
extends EditorScenePostImport

func _post_import(scene: Node) -> Object:
	print("POST IMPORT RUNNING")
	_apply_cel_shader(scene)
	return scene

func _apply_cel_shader(node: Node) -> void:
	print("Visiting node: ", node.name, " type: ", node.get_class())
	if node is MeshInstance3D:
		var mesh = node.mesh
		if mesh == null:
			print("  No mesh found!")
		else:
			print("  Mesh found: ", mesh.get_surface_count(), " surfaces")
			for i in mesh.get_surface_count():
				var mat = mesh.surface_get_material(i)
				print("  Surface ", i, " material: ", mat)
				if mat is StandardMaterial3D:
					var cel_mat = ShaderMaterial.new()
					cel_mat.shader = load("res://assets/materials/cel_shader.gdshader")
					cel_mat.set_shader_parameter("albedo", mat.albedo_color)
					if mat.albedo_texture != null:
						cel_mat.set_shader_parameter("texture_albedo", mat.albedo_texture)
						cel_mat.set_shader_parameter("use_texture", true)
					else:
						cel_mat.set_shader_parameter("use_texture", false)
					cel_mat.set_shader_parameter("shading_steps", 2.0)
					cel_mat.set_shader_parameter("shadow_softness", 0.0)
					cel_mat.set_shader_parameter("ambient_light", 0.3)
					node.set_surface_override_material(i, cel_mat)
					print("  Cel shader applied!")
	for child in node.get_children():
		_apply_cel_shader(child)
