@tool
extends EditorScenePostImport

const WALL_OBJECT_BAKER = preload("res://assets/materials/wall_object_baker.gd")
const MAX_RAMP_STOPS := 8
## Blender materials whose name starts with this get the grass shader
## (blotchy edges, patches, cloud shadows). Everything else stays plain cel.
const GRASS_PREFIX := "grass"
const GRASS_SHADER := "res://assets/materials/cel_shader_grass.gdshader"
## Blender materials whose name starts with this become water: the water shader with its
## settings copied from WATER_TEMPLATE, tinted with the colour authored in Blender, and the
## mesh joins the "water" group (fishing, ripples). Different water colours = different
## Blender materials (water, water_bath, ...); the behaviour is the same everywhere. A name
## containing "inside" (water_inside) is drawn in the lit tone everywhere.
const WATER_PREFIX := "water"
const WATER_TEMPLATE := "res://assets/materials/b1_lobby_pool_water_surface_settings.tres"
## Metres per local unit in the lobby pool, which the template's ripple sizes were tuned in.
const WATER_TEMPLATE_UNIT := 0.5

func _post_import(scene: Node) -> Object:
	_apply_cel_shader(scene)
	return scene

func _apply_cel_shader(node: Node) -> void:
	if node is MeshInstance3D:
		# gives each "-wo" piece its own outward direction (see the baker)
		WALL_OBJECT_BAKER.bake_mesh_instance(node)
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

					# Blender's Color Ramp can't be exported, so tools/blender_cel_props.py
					# copies it into material custom properties, which arrive here as the
					# "extras" meta: cel_steps, cel_color (brightest stop, linear) and the
					# whole ramp as cel_ramp = [pos, r, g, b, ...] plus cel_interp.
					var steps := 2.0
					var albedo: Color = mat.albedo_color
					var extras = mat.get_meta("extras", {})
					if extras is Dictionary:
						if extras.has("cel_steps"):
							steps = clampf(float(extras["cel_steps"]), 2.0, 8.0)
						var ramp_color = extras.get("cel_color")
						if ramp_color is Array and ramp_color.size() >= 3:
							# Blender colours are linear; the shader wants sRGB
							albedo = Color(ramp_color[0], ramp_color[1], ramp_color[2]).linear_to_srgb()
						if not mat.resource_name.ends_with("-po"):
							var has_ramp := _apply_ramp(cel_mat, extras)
							# grass swaps in its own shader (it needs the ramp)
							if has_ramp and mat.resource_name.to_lower().begins_with(GRASS_PREFIX):
								cel_mat.shader = load(GRASS_SHADER)

					cel_mat.set_shader_parameter("albedo", albedo)
					if mat.albedo_texture != null:
						cel_mat.set_shader_parameter("texture_albedo", mat.albedo_texture)
						cel_mat.set_shader_parameter("use_texture", true)
					else:
						cel_mat.set_shader_parameter("use_texture", false)
					if not mat.resource_name.ends_with("-po"):
						cel_mat.set_shader_parameter("shading_steps", steps)
						cel_mat.set_shader_parameter("shadow_softness", 0.0)
						# the darkest band must sit below the next step, or 3+ step
						# materials lose their bottom band to the ambient floor
						cel_mat.set_shader_parameter("ambient_light", 0.3 if steps <= 2.0 else minf(0.3, 0.5 / steps))
					if mat.resource_name.to_lower().begins_with(WATER_PREFIX):
						var water_mat := _make_water_material(albedo, mat.resource_name.to_lower().contains("inside"))
						if water_mat != null:
							node.set_surface_override_material(i, water_mat)
							node.add_to_group(&"water", true) # persistent: saved into the imported scene
							continue
					node.set_surface_override_material(i, cel_mat)
			if has_poche:
				node.set_script(load("res://assets/materials/poche_object.gd"))
	for child in node.get_children():
		_apply_cel_shader(child)

## Hands the Blender ramp (sorted stops of position + linear rgb) to the shader,
## which then lights with the ramp's own colours instead of dimming the albedo.
## Returns false when the material has no usable ramp.
func _apply_ramp(cel_mat: ShaderMaterial, extras: Dictionary) -> bool:
	var ramp = extras.get("cel_ramp")
	# one stop (4 numbers) is a valid ramp: a flat colour that ignores the light
	if not (ramp is Array) or ramp.size() < 4 or ramp.size() % 4 != 0:
		return false
	var stops: int = ramp.size() / 4
	if stops > MAX_RAMP_STOPS:
		push_warning("cel ramp has %d stops, only the first %d are used" % [stops, MAX_RAMP_STOPS])
		stops = MAX_RAMP_STOPS
	var data := PackedVector4Array()
	data.resize(MAX_RAMP_STOPS)
	for s in stops:
		# shader layout: rgb = colour, a = stop position
		data[s] = Vector4(ramp[s * 4 + 1], ramp[s * 4 + 2], ramp[s * 4 + 3], ramp[s * 4])
	cel_mat.set_shader_parameter("ramp_data", data)
	cel_mat.set_shader_parameter("ramp_count", stops)
	cel_mat.set_shader_parameter("ramp_linear", str(extras.get("cel_interp", "CONSTANT")) != "CONSTANT")
	return true

## A fresh copy of the template water material (so every water mesh keeps its own ripple
## state) with water_color set to the Blender colour. Null if the template is missing.
func _make_water_material(color: Color, indoor: bool) -> ShaderMaterial:
	var template := load(WATER_TEMPLATE) as ShaderMaterial
	if template == null:
		push_warning("water template not found: %s" % WATER_TEMPLATE)
		return null
	var water := template.duplicate() as ShaderMaterial
	water.set_shader_parameter("water_color", color)
	# world-space mode: waves, pattern and ripples in metres, flat emissive colour, cloud shadows.
	# It doesn't depend on the mesh having a usable UV map, or on the mesh's scale.
	water.set_shader_parameter("world_space", true)
	# the template's light pattern is a reflection of the lobby's ceiling lights. Water whose
	# Blender material name contains "inside" (water_inside) is always in the lit tone, outdoor
	# water is just its flat Blender colour.
	# (indoor water takes the lit tone everywhere: a half-lit pool just looks like a stray line)
	water.set_shader_parameter("light_pattern_enabled", false)
	water.set_shader_parameter("light_always_on", indoor)
	# the template's ripple sizes are in the lobby pool's local units; convert them to metres
	for param in ["ripple_wavelength", "ripple_speed", "ripple_noise_strength"]:
		water.set_shader_parameter(param, float(template.get_shader_parameter(param)) * WATER_TEMPLATE_UNIT)
	water.set_shader_parameter("ripple_falloff", float(template.get_shader_parameter("ripple_falloff")) / WATER_TEMPLATE_UNIT)
	return water
