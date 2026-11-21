extends RefCounted
## Gives every piece of "wall object" geometry (materials ending in "-wo") its
## own "away from the wall" direction, so cel_shader_wall_object can hide each
## piece when the camera is behind the wall it's mounted on.
##
## Wall objects can share one mesh with the rest of a room, on walls facing all
## sorts of ways (including angled ones), so one direction per material or per
## scene can't describe them. Each connected piece of "-wo" geometry gets its
## outward direction written into the vertex colour:
##   rgb = direction * 0.5 + 0.5 (mesh space), a = BAKED_ALPHA
## A piece with no usable direction (e.g. a closed box) gets a = 0 and the
## shader falls back to its wall_normal uniform. Meshes that were never baked
## keep the default vertex colour (a = 1), which the shader also treats as
## "not baked".
##
## Pieces should be open on the wall side (no face touching the wall), which is
## how the lobby's are built.
##
## This runs at import (cel_shader_import.gd) and again when a level loads
## (Main), so it still works if an imported file is stale. It skips anything
## already baked.

const WALL_OBJECT_SHADER := "cel_shader_wall_object.gdshader"
const BAKED_ALPHA: float = 0.5

## A piece whose normals mostly cancel out (e.g. a closed box) has no usable
## outward direction; below this fraction it stays unbaked.
const MIN_NORMAL_COHERENCE: float = 0.15
## Fraction of a piece's depth that its area centroid must sit off-centre by to
## tell front from back. The lobby's open boxes are about 30%.
const MIN_DEPTH_OFFSET: float = 0.05

## Bakes every mesh under root. Meshes shared between nodes are baked once.
static func bake_tree(root: Node) -> void:
	_bake_node(root, {})

static func _bake_node(node: Node, baked_meshes: Dictionary) -> void:
	if node is MeshInstance3D:
		bake_mesh_instance(node, baked_meshes)
	for child in node.get_children():
		_bake_node(child, baked_meshes)

static func bake_mesh_instance(node: MeshInstance3D, baked_meshes: Dictionary = {}) -> void:
	var old_mesh := node.mesh as ArrayMesh
	if old_mesh == null:
		return
	if baked_meshes.has(old_mesh):
		node.mesh = baked_meshes[old_mesh]
		return

	var to_bake: Array[int] = []
	for i in old_mesh.get_surface_count():
		if _is_wall_object_surface(node, old_mesh, i) and not _is_baked(old_mesh, i):
			to_bake.append(i)
	if to_bake.is_empty():
		baked_meshes[old_mesh] = old_mesh
		return

	var new_mesh := ArrayMesh.new()
	new_mesh.resource_name = old_mesh.resource_name
	for i in old_mesh.get_surface_count():
		var arrays := old_mesh.surface_get_arrays(i)
		if i in to_bake:
			arrays[Mesh.ARRAY_COLOR] = _wall_normal_colors(arrays)
		new_mesh.add_surface_from_arrays(old_mesh.surface_get_primitive_type(i), arrays)
		new_mesh.surface_set_name(i, old_mesh.surface_get_name(i))
		new_mesh.surface_set_material(i, old_mesh.surface_get_material(i))
	baked_meshes[old_mesh] = new_mesh
	node.mesh = new_mesh

## At import the surface still has its Blender material ("...-wo"); once
## cel_shader_import.gd has run, the node carries the wall-object ShaderMaterial.
static func _is_wall_object_surface(node: MeshInstance3D, mesh: ArrayMesh, surface: int) -> bool:
	var override := node.get_surface_override_material(surface) as ShaderMaterial
	if override != null and override.shader != null:
		return override.shader.resource_path.ends_with(WALL_OBJECT_SHADER)
	var mat := mesh.surface_get_material(surface)
	return mat != null and mat.resource_name.ends_with("-wo")

static func _is_baked(mesh: ArrayMesh, surface: int) -> bool:
	var colors = mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
	if colors == null or (colors as PackedColorArray).is_empty():
		return false
	return (colors as PackedColorArray)[0].a < 0.75

static func _wall_normal_colors(arrays: Array) -> PackedColorArray:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors := PackedColorArray()
	colors.resize(verts.size())
	colors.fill(Color(0.5, 0.5, 0.5, 0.0))
	if arrays[Mesh.ARRAY_NORMAL] == null:
		return colors
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]

	var tri_indices := PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] != null:
		tri_indices = arrays[Mesh.ARRAY_INDEX]
	else:
		tri_indices.resize(verts.size())
		for i in verts.size():
			tri_indices[i] = i

	# Weld vertices sharing a position so a piece split by UV/normal seams
	# still counts as one piece, then union triangles that share a vertex.
	var weld_ids := {}
	var vert_weld := PackedInt32Array()
	vert_weld.resize(verts.size())
	var parent: Array[int] = []
	for i in verts.size():
		var key := Vector3i((verts[i] * 1000.0).round())
		if not weld_ids.has(key):
			weld_ids[key] = parent.size()
			parent.append(parent.size())
		vert_weld[i] = weld_ids[key]
	for t in tri_indices.size() / 3:
		var root_a := _find_root(parent, vert_weld[tri_indices[t * 3]])
		for k in [1, 2]:
			var root_b := _find_root(parent, vert_weld[tri_indices[t * 3 + k]])
			if root_a != root_b:
				parent[root_b] = root_a

	# Per piece: the axis its faces line up along (sign unreliable, see below),
	# its total area, and its area-weighted centroid.
	var normal_sums := {}
	var areas := {}
	var centroid_sums := {}
	for t in tri_indices.size() / 3:
		var i0 := tri_indices[t * 3]
		var i1 := tri_indices[t * 3 + 1]
		var i2 := tri_indices[t * 3 + 2]
		var area := (verts[i1] - verts[i0]).cross(verts[i2] - verts[i0]).length() * 0.5
		var root := _find_root(parent, vert_weld[i0])
		var avg_normal := (normals[i0] + normals[i1] + normals[i2]) / 3.0
		normal_sums[root] = normal_sums.get(root, Vector3.ZERO) + avg_normal * area
		areas[root] = areas.get(root, 0.0) + area
		centroid_sums[root] = centroid_sums.get(root, Vector3.ZERO) + (verts[i0] + verts[i1] + verts[i2]) / 3.0 * area

	var axes := {}
	for root in areas:
		var total_area: float = areas[root]
		var normal_sum: Vector3 = normal_sums[root]
		if total_area > 0.0 and normal_sum.length() / total_area >= MIN_NORMAL_COHERENCE:
			axes[root] = normal_sum.normalized()

	# The face normals themselves can't be trusted for the sign (they're often
	# flipped in the export and the material is double-sided, so nobody
	# notices). The open side against the wall has no face, so the piece's area
	# sits nearer its front panel than the middle of its depth: the way that
	# offset points is "out". A symmetric (closed) piece has no offset and
	# stays unbaked.
	var depth_min := {}
	var depth_max := {}
	for i in verts.size():
		var root := _find_root(parent, vert_weld[i])
		if not axes.has(root):
			continue
		var depth := verts[i].dot(axes[root])
		depth_min[root] = minf(depth_min.get(root, depth), depth)
		depth_max[root] = maxf(depth_max.get(root, depth), depth)
	var outward := {}
	for root in axes:
		var axis: Vector3 = axes[root]
		var extent: float = depth_max[root] - depth_min[root]
		var centroid_depth: float = (centroid_sums[root] as Vector3).dot(axis) / areas[root]
		var offset: float = centroid_depth - (depth_min[root] + depth_max[root]) * 0.5
		if extent > 0.0 and absf(offset) >= extent * MIN_DEPTH_OFFSET:
			outward[root] = axis * signf(offset)

	for i in verts.size():
		var root := _find_root(parent, vert_weld[i])
		if outward.has(root):
			var dir: Vector3 = outward[root]
			colors[i] = Color(dir.x * 0.5 + 0.5, dir.y * 0.5 + 0.5, dir.z * 0.5 + 0.5, BAKED_ALPHA)
	return colors

static func _find_root(parent: Array[int], index: int) -> int:
	while parent[index] != index:
		parent[index] = parent[parent[index]]
		index = parent[index]
	return index
