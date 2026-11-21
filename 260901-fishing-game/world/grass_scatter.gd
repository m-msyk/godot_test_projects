@tool
class_name GrassScatter
extends Node3D
## Scatters grass tufts over every terrain surface that uses the grass shader
## (Blender materials named "grass...", see cel_shader_import.gd).
##
## Tufts are camera-facing quads drawn by grass_tuft.gdshader, batched into
## MultiMesh chunks that fade out with distance. Nothing is saved in the scene:
## the tufts are rebuilt every time this node enters the tree (and when you press
## Rebuild in the inspector), always the same for a given seed.
##
## Put it next to the node that holds the terrain and point source_root at it.
## Faces that are too steep, and surfaces with other materials (roads, buildings),
## get no tufts, and tufts keep a small distance away from anything that isn't grass.

const GRASS_SHADER_PATH := "res://assets/materials/cel_shader_grass.gdshader"
const TUFT_SHADER: Shader = preload("res://assets/materials/grass_tuft.gdshader")
## Grid cell size (metres) for the keep-away lookup.
const OBSTACLE_CELL := 4.0
## Only things within this height range of a tuft's base count as in its way, so a
## tree canopy overhead doesn't clear the grass underneath it.
const OBSTACLE_BELOW := 0.4
const OBSTACLE_ABOVE := 1.2

## Node whose MeshInstance3D descendants are searched for grass. Empty = parent.
@export var source_root: NodePath
## Tufts per square metre of grass surface.
@export_range(0.01, 4.0, 0.01) var density: float = 0.35
## Tuft height range in metres (width follows).
@export_range(0.1, 5.0, 0.05) var min_height: float = 0.9
@export_range(0.1, 5.0, 0.05) var max_height: float = 1.5
## Skip faces steeper than this.
@export_range(0.0, 89.0, 1.0) var max_slope_degrees: float = 40.0
## Tufts stay at least this far (metres, measured along the ground) from any
## non-grass surface: roads, paths, walls, trunks, water.
@export_range(0.0, 5.0, 0.05) var min_edge_distance: float = 0.6
@export var random_seed: int = 1
## Chunk size in metres: bigger = fewer draw calls, smaller = better culling.
@export_range(8.0, 128.0, 1.0) var chunk_size: float = 32.0
## Chunks beyond this distance from the camera aren't drawn. 0 = always.
@export_range(0.0, 1000.0, 5.0) var fade_distance: float = 160.0
@export var enabled: bool = true:
	set(value):
		enabled = value
		visible = value
@export_tool_button("Rebuild tufts", "Reload") var rebuild_button: Callable = build

func _ready() -> void:
	# wait a frame so the terrain nodes (siblings) are in the tree
	build.call_deferred()

func build() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		child.queue_free()

	var root: Node = get_node_or_null(source_root) if not source_root.is_empty() else get_parent()
	if root == null:
		push_warning("GrassScatter: source_root not found")
		return

	var triangles := PackedVector3Array() # a, b, c per grass triangle, world space
	var cumulative := PackedFloat64Array() # running total of grass triangle areas
	var total_area := 0.0
	var grass_material: ShaderMaterial = null
	var min_up := cos(deg_to_rad(max_slope_degrees))
	var other_surfaces: Array = [] # [Transform3D, Mesh, surface index] for the keep-away lookup
	var bounds := Rect2()
	var has_bounds := false

	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		var xf: Transform3D = mi.global_transform
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s) as ShaderMaterial
			if mat == null or mat.shader == null or mat.shader.resource_path != GRASS_SHADER_PATH:
				other_surfaces.append([xf, mi.mesh, s])
				continue
			if grass_material == null:
				grass_material = mat
			var arrays := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var index = arrays[Mesh.ARRAY_INDEX]
			var count: int = (index.size() if index != null else verts.size()) / 3
			for t in count:
				var i0: int = index[t * 3] if index != null else t * 3
				var i1: int = index[t * 3 + 1] if index != null else t * 3 + 1
				var i2: int = index[t * 3 + 2] if index != null else t * 3 + 2
				var a := xf * verts[i0]
				var b := xf * verts[i1]
				var c := xf * verts[i2]
				var cross := (b - a).cross(c - a)
				var area := cross.length() * 0.5
				if area <= 0.0001 or absf(cross.normalized().y) < min_up:
					continue
				triangles.append_array([a, b, c])
				total_area += area
				cumulative.append(total_area)
				for v in [a, b, c]:
					var p2 := Vector2(v.x, v.z)
					if has_bounds:
						bounds = bounds.expand(p2)
					else:
						bounds = Rect2(p2, Vector2.ZERO)
						has_bounds = true

	if grass_material == null or cumulative.is_empty():
		return

	var obstacles := _build_obstacles(other_surfaces, bounds.grow(min_edge_distance + 0.1)) if min_edge_distance > 0.0 else {}

	var material := ShaderMaterial.new()
	material.shader = TUFT_SHADER
	_copy_shared_parameters(grass_material, material)

	var quad := QuadMesh.new()
	quad.size = Vector2(1.1, 1.0)
	quad.center_offset = Vector3(0.0, 0.5, 0.0) # pivot at the base of the tuft

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var chunks := {} # Vector2i -> Array[Transform3D]
	var tuft_count := int(total_area * density)
	var placed := 0
	for n in tuft_count:
		# always draw the same random numbers, so rejected tufts don't shuffle the rest
		var tri := _pick_triangle(cumulative, rng.randf() * total_area)
		var r1 := sqrt(rng.randf())
		var r2 := rng.randf()
		var h := rng.randf_range(min_height, max_height)
		var p: Vector3 = triangles[tri * 3] * (1.0 - r1) \
				+ triangles[tri * 3 + 1] * (r1 * (1.0 - r2)) \
				+ triangles[tri * 3 + 2] * (r1 * r2)
		if not obstacles.is_empty() and _blocked(obstacles, p):
			continue
		var key := Vector2i(floori(p.x / chunk_size), floori(p.z / chunk_size))
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(Transform3D(Basis.from_scale(Vector3(h, h, h)), to_local(p)))
		placed += 1

	for key in chunks:
		var transforms: Array = chunks[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = quad
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Chunk_%d_%d" % [key.x, key.y]
		mmi.multimesh = mm
		mmi.material_override = material
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.extra_cull_margin = 3.0
		if fade_distance > 0.0:
			mmi.visibility_range_end = fade_distance
		add_child(mmi)

	print("GrassScatter: %d tufts (%d rejected near non-grass) in %d chunks over %.0f m2" % [placed, tuft_count - placed, chunks.size(), total_area])

## Index of the triangle whose cumulative-area range contains `value`.
func _pick_triangle(cumulative: PackedFloat64Array, value: float) -> int:
	var lo := 0
	var hi := cumulative.size() - 1
	while lo < hi:
		var mid := (lo + hi) / 2
		if cumulative[mid] < value:
			lo = mid + 1
		else:
			hi = mid
	return lo

## Gives the tuft material the same ramp and effect settings as the ground, so a
## tuft always matches the grass it stands on.
func _copy_shared_parameters(from: ShaderMaterial, to: ShaderMaterial) -> void:
	for uniform in TUFT_SHADER.get_shader_uniform_list():
		var param_name: String = uniform["name"]
		var value = from.get_shader_parameter(param_name)
		if value != null:
			to.set_shader_parameter(param_name, value)

## Grid of every non-grass triangle near the grass (world space), keyed by cell.
## Returns { "tris": PackedVector3Array, "cells": { Vector2i: PackedInt32Array } }.
func _build_obstacles(surfaces: Array, area: Rect2) -> Dictionary:
	var tris := PackedVector3Array()
	var cells := {}
	for entry in surfaces:
		var xf: Transform3D = entry[0]
		var mesh: Mesh = entry[1]
		var arrays := mesh.surface_get_arrays(entry[2])
		if arrays[Mesh.ARRAY_VERTEX] == null:
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var index = arrays[Mesh.ARRAY_INDEX]
		var count: int = (index.size() if index != null else verts.size()) / 3
		for t in count:
			var a := xf * verts[index[t * 3] if index != null else t * 3]
			var b := xf * verts[index[t * 3 + 1] if index != null else t * 3 + 1]
			var c := xf * verts[index[t * 3 + 2] if index != null else t * 3 + 2]
			var lo := Vector2(minf(a.x, minf(b.x, c.x)), minf(a.z, minf(b.z, c.z)))
			var hi := Vector2(maxf(a.x, maxf(b.x, c.x)), maxf(a.z, maxf(b.z, c.z)))
			if not area.intersects(Rect2(lo, hi - lo)):
				continue
			var id := tris.size() / 3
			tris.append_array([a, b, c])
			var c0 := Vector2i(floori((lo.x - min_edge_distance) / OBSTACLE_CELL), floori((lo.y - min_edge_distance) / OBSTACLE_CELL))
			var c1 := Vector2i(floori((hi.x + min_edge_distance) / OBSTACLE_CELL), floori((hi.y + min_edge_distance) / OBSTACLE_CELL))
			for cx in range(c0.x, c1.x + 1):
				for cy in range(c0.y, c1.y + 1):
					var key := Vector2i(cx, cy)
					if not cells.has(key):
						cells[key] = PackedInt32Array()
					cells[key].append(id)
	return {"tris": tris, "cells": cells}

## True if a non-grass surface passes within min_edge_distance of this ground point.
func _blocked(obstacles: Dictionary, p: Vector3) -> bool:
	var key := Vector2i(floori(p.x / OBSTACLE_CELL), floori(p.z / OBSTACLE_CELL))
	var cells: Dictionary = obstacles["cells"]
	if not cells.has(key):
		return false
	var tris: PackedVector3Array = obstacles["tris"]
	var p2 := Vector2(p.x, p.z)
	for id in cells[key]:
		var a := tris[id * 3]
		var b := tris[id * 3 + 1]
		var c := tris[id * 3 + 2]
		if minf(a.y, minf(b.y, c.y)) > p.y + OBSTACLE_ABOVE or maxf(a.y, maxf(b.y, c.y)) < p.y - OBSTACLE_BELOW:
			continue
		var a2 := Vector2(a.x, a.z)
		var b2 := Vector2(b.x, b.z)
		var c2 := Vector2(c.x, c.z)
		if _point_in_triangle(p2, a2, b2, c2):
			return true
		if minf(_segment_distance(p2, a2, b2), minf(_segment_distance(p2, b2, c2), _segment_distance(p2, c2, a2))) < min_edge_distance:
			return true
	return false

static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq < 0.00000001:
		return p.distance_to(a)
	return p.distance_to(a + ab * clampf((p - a).dot(ab) / len_sq, 0.0, 1.0))

static func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	if absf((b - a).cross(c - a)) < 0.000001:
		return false # edge-on (a wall): only the distance test applies
	var d1 := (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y)
	var d2 := (p.x - c.x) * (b.y - c.y) - (b.x - c.x) * (p.y - c.y)
	var d3 := (p.x - a.x) * (c.y - a.y) - (c.x - a.x) * (p.y - a.y)
	var has_neg := d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var has_pos := d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (has_neg and has_pos)
