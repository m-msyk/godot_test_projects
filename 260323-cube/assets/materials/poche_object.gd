extends MeshInstance3D

func _ready():
	add_to_group("poche")

func update_poche_color(color: Color) -> void:
	for i in get_surface_override_material_count():
		var mat = get_surface_override_material(i)
		if mat:
			mat.set_shader_parameter("poche_color", color)
