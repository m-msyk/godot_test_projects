@tool
extends EditorScenePostImport

func _post_import(scene: Node) -> Object:
	_apply_cel_shader(scene)
	return scene

func _apply_cel_shader(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh = node.mesh
		if mesh != null:
			var has_poche = false
			for i in mesh.get_surface_count():
				var mat = mesh.surface_get_material(i)
				if mat is StandardMaterial3D:
					var shader_path = "res://assets/materials/cel_shader.gdshader"
					if mat.resource_name.ends_with("-bf"):
						shader_path = "res://assets/materials/cel_shader_backface_culling.gdshader"
					elif mat.resource_name.ends_with("-wo"):
						shader_path = "res://assets/materials/cel_shader_wall_object.gdshader"
					elif mat.resource_name.ends_with("-po"):
						shader_path = "res://assets/materials/cel_shader_poche.gdshader"
						has_poche = true
					var cel_mat = ShaderMaterial.new()
					cel_mat.shader = load(shader_path)
					cel_mat.set_shader_parameter("albedo", mat.albedo_color)
					if mat.albedo_texture != null:
						cel_mat.set_shader_parameter("texture_albedo", mat.albedo_texture)
						cel_mat.set_shader_parameter("use_texture", true)
					else:
						cel_mat.set_shader_parameter("use_texture", false)
					if not mat.resource_name.ends_with("-po"):
						cel_mat.set_shader_parameter("shading_steps", 2.0)
						cel_mat.set_shader_parameter("shadow_softness", 0.0)
						cel_mat.set_shader_parameter("ambient_light", 0.3)
					node.set_surface_override_material(i, cel_mat)
			if has_poche:
				node.set_script(load("res://assets/materials/poche_object.gd"))
	for child in node.get_children():
		_apply_cel_shader(child)
