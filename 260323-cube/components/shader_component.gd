class_name ShaderComponent extends Node

@export var shading_steps: float = 2.0
@export var shadow_softness: float = 0.05
@export var ambient_light: float = 0.25
@export var rim_strength: float = 0.0
@export var rim_sharpness: float = 3.0

@export var model: Node3D

func _ready() -> void:
	if model == null:
		return
	_apply_to_all_meshes(model)

func _apply_to_all_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_apply_shader_parameters(node)
	for child in node.get_children():
		_apply_to_all_meshes(child)

func _apply_shader_parameters(mesh: MeshInstance3D) -> void:
	for i in mesh.get_surface_override_material_count():
		var mat = mesh.get_surface_override_material(i)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("shading_steps", shading_steps)
			mat.set_shader_parameter("shadow_softness", shadow_softness)
			mat.set_shader_parameter("ambient_light", ambient_light)
			mat.set_shader_parameter("rim_strength", rim_strength)
			mat.set_shader_parameter("rim_sharpness", rim_sharpness)
