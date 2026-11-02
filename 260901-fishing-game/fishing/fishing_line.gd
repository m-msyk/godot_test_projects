class_name FishingLine extends MeshInstance3D

@export var start_point: Node3D
@export var slack_amount: float = 0.03
@export var segment_count: int = 12
@export var line_color: Color = Color(1, 1, 1, 1)
@export var line_width: float = 0.0015
@export var taut_tween_duration: float = 0.2

var _target: Node3D = null
var _immediate_mesh: ImmediateMesh
var _slack_multiplier: float = 1.0
var _taut_tween: Tween

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_immediate_mesh = ImmediateMesh.new()
	mesh = _immediate_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = line_color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat
	visible = false

func get_start_position() -> Vector3:
	return start_point.global_position if start_point else Vector3.ZERO

func set_target(target: Node3D) -> void:
	_target = target
	_slack_multiplier = 1.0
	visible = true

func clear_target() -> void:
	_target = null
	visible = false
	_immediate_mesh.clear_surfaces()
	if _taut_tween:
		_taut_tween.kill()

func set_taut(taut: bool) -> void:
	if _taut_tween:
		_taut_tween.kill()
	_taut_tween = create_tween()
	_taut_tween.tween_property(self, "_slack_multiplier", 0.0 if taut else 1.0, taut_tween_duration)

func _process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or start_point == null:
		return
	_draw_line(start_point.global_position, _target.global_position)

func _draw_line(from: Vector3, to: Vector3) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var points: Array[Vector3] = []
	var sag := slack_amount * _slack_multiplier
	for i in range(segment_count + 1):
		var t := float(i) / float(segment_count)
		var point := from.lerp(to, t)
		point.y -= sag * 4.0 * t * (1.0 - t)  # simple parabolic sag
		points.append(point)

	# Build a thin camera-facing ribbon instead of a native line primitive,
	# since line primitives have no adjustable width in Forward+.
	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var half_width := line_width * 0.5
	for i in points.size():
		var point: Vector3 = points[i]
		var dir: Vector3
		if i == 0:
			dir = (points[1] - points[0]).normalized()
		elif i == points.size() - 1:
			dir = (points[i] - points[i - 1]).normalized()
		else:
			dir = (points[i + 1] - points[i - 1]).normalized()
		var to_camera := (camera.global_position - point).normalized()
		var side := dir.cross(to_camera).normalized() * half_width
		_immediate_mesh.surface_add_vertex(point + side)
		_immediate_mesh.surface_add_vertex(point - side)
	_immediate_mesh.surface_end()
