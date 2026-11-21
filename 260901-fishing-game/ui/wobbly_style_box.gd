@tool
class_name WobblyStyleBox extends StyleBox
## A filled panel with no border and a softly wobbly outline, like the text boxes in
## Animal Crossing. The edge is never antialiased, so it stays crisp pixels. Use it
## anywhere a StyleBox goes (Panel, PanelContainer, Button, theme styles...).
##
## The wobble drifts slowly along the edge, like soft cloud shadows moving across the
## grass. It moves in steps (animation_fps) so it reads as pixel art, and different
## sized panels wobble differently. To do this the style asks the panels using it to
## redraw a few times a second while the game runs; it stays still in the editor.
##
## Set the content margins (StyleBox > Content Margin) to keep text off the edge.

@export var color: Color = Color(0.929, 0.878, 0.761)
## Roundness of the corners, in pixels.
@export_range(0.0, 64.0, 0.5) var corner_radius: float = 8.0
## How far the edge wanders in and out, in pixels (0 = a plain rounded rectangle).
@export_range(0.0, 8.0, 0.1) var wobble_amount: float = 1.6
## Roughly how long one wobble is along the edge, in pixels. Smaller = busier.
@export_range(8.0, 200.0, 1.0) var wobble_length: float = 56.0
## Change this to get a different wobble pattern.
@export var wobble_seed: int = 1
## Let the wobble drift over time.
@export var animate: bool = true
## How fast the wobble drifts. 1.0 is a slow, calm drift (one wobble takes several seconds).
@export_range(0.0, 4.0, 0.05) var animation_speed: float = 1.0
## Redraws per second. Low keeps it stepped and pixel-like and costs almost nothing.
@export_range(1.0, 30.0, 1.0) var animation_fps: float = 8.0

const STEP := 5.0 # distance between outline points, in pixels
## Drift speed (radians per second at animation_speed 1) of the three wobble layers;
## different speeds and directions keep it from looking like a rotating pattern.
const DRIFT := [0.9, -1.3, 1.7]

var _driving: bool = false
var _last_step: int = -1

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	_start_driver()
	var points := _outline(rect)
	if points.size() < 3:
		return
	var colors := PackedColorArray()
	colors.resize(points.size())
	colors.fill(color)
	# no antialiasing on purpose: the edge is hard pixels, like the rest of the pixel art
	RenderingServer.canvas_item_add_polygon(to_canvas_item, points, colors)

## Starts the per-frame check that tells panels to redraw (runtime only).
func _start_driver() -> void:
	if _driving or not animate or Engine.is_editor_hint():
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	_driving = true
	tree.process_frame.connect(_tick)

func _tick() -> void:
	if not animate:
		return
	var step := int(_time() * animation_fps)
	if step != _last_step:
		_last_step = step
		emit_changed() # every panel using this style redraws

func _time() -> float:
	return float(Time.get_ticks_msec()) / 1000.0 if (animate and not Engine.is_editor_hint()) else 0.0

## The wobbly rounded-rectangle outline, kept inside `rect`.
func _outline(rect: Rect2) -> PackedVector2Array:
	var inset := wobble_amount + 0.5
	var r := Rect2(rect.position + Vector2(inset, inset), rect.size - Vector2(inset, inset) * 2.0)
	if r.size.x <= 2.0 or r.size.y <= 2.0:
		return PackedVector2Array()
	var radius := minf(corner_radius, minf(r.size.x, r.size.y) * 0.5)

	# base outline: [position, outward normal], walking clockwise from the top edge
	var base: Array = []
	var corners := [
		[Vector2(r.end.x - radius, r.position.y + radius), -PI * 0.5], # top right
		[Vector2(r.end.x - radius, r.end.y - radius), 0.0], # bottom right
		[Vector2(r.position.x + radius, r.end.y - radius), PI * 0.5], # bottom left
		[Vector2(r.position.x + radius, r.position.y + radius), PI], # top left
	]
	var arc_steps := maxi(int(ceil(radius * PI * 0.5 / STEP)), 2)
	for c in 4:
		var centre: Vector2 = corners[c][0]
		var a0: float = corners[c][1]
		for i in arc_steps + 1:
			var a := a0 + (PI * 0.5) * float(i) / float(arc_steps)
			var n := Vector2(cos(a), sin(a))
			base.append([centre + n * radius, n])
		# straight edge to the next corner
		var next_c: int = (c + 1) % 4
		var from: Vector2 = base[base.size() - 1][0]
		var to: Vector2 = corners[next_c][0] + Vector2(cos(corners[next_c][1]), sin(corners[next_c][1])) * radius
		var edge_n := Vector2(cos(a0 + PI * 0.5), sin(a0 + PI * 0.5))
		var length := from.distance_to(to)
		var segments := int(length / STEP)
		for i in range(1, segments):
			base.append([from.lerp(to, float(i) / float(segments)), edge_n])

	# perimeter length at each point, for a wobble that closes up seamlessly
	var perimeter := 0.0
	var lengths: Array[float] = [0.0]
	for i in range(1, base.size()):
		perimeter += (base[i][0] as Vector2).distance_to(base[i - 1][0] as Vector2)
		lengths.append(perimeter)
	perimeter += (base[0][0] as Vector2).distance_to(base[base.size() - 1][0] as Vector2)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(int(rect.size.x), int(rect.size.y), wobble_seed))
	var phases := [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
	var waves := [maxi(int(round(perimeter / wobble_length)), 1), maxi(int(round(perimeter / (wobble_length * 0.43))), 2), maxi(int(round(perimeter / (wobble_length * 0.21))), 3)]
	var amps := [0.70, 0.26, 0.04]

	# the wobble waves travel along the edge as time passes (quantised to animation_fps)
	var drift := (floorf(_time() * animation_fps) / animation_fps) * animation_speed

	var points := PackedVector2Array()
	for i in base.size():
		var t: float = lengths[i] / perimeter * TAU
		var w := 0.0
		for k in 3:
			w += amps[k] * sin(t * float(waves[k]) + float(phases[k]) + drift * float(DRIFT[k]))
		# w is within -1..1; push the edge in or out by up to wobble_amount
		points.append((base[i][0] as Vector2) + (base[i][1] as Vector2) * w * wobble_amount)
	return points
