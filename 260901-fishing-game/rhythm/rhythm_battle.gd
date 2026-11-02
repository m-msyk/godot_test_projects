class_name RhythmBattle extends Node2D

signal battle_complete(fish_caught: bool)

enum WinCondition { METER, MISS_COUNT }

const NOTE_SCENE = preload("res://rhythm/note.tscn")

const SCROLL_SPEED: float = 200.0
const TARGET_Y: float = 190.0
const HIT_WINDOW_PERFECT: float = 0.050
const HIT_WINDOW_OK: float = 0.100
const LANE_SPACING: float = 60.0
const TRIM_WIDTH: float = 1.0
const PLAY_AREA_LEFT: float = 225.0
const PLAY_AREA_WIDTH: float = 120.0
const MIN_LEAD_IN: float = 0.3
const LANE_COLORS: Array = [Color(0.2, 0.4, 1.0), Color(1.0, 0.2, 0.2)]
const TARGET_LINE_DEFAULT: Color = Color(1.0, 1.0, 1.0)
const TARGET_LINE_FLASH: Color = Color(1.0, 1.0, 0.0)

const BASE_DAMAGE: float = 2.0
const BASE_COMBO_GROWTH: float = 0.05

const LANE_DARKEN: float = 0.45
const TRIM_DARKEN: float = 0.7
const RESAMPLE_THRESHOLD: float = 0.5

## Cached across battles — only replaced once the background has changed
## enough (see RESAMPLE_THRESHOLD) so fishing repeatedly in the same spot
## doesn't cause the lane color to flicker/reset each time.
static var _cached_bg_color: Color = Color(0.35, 0.35, 0.35)
static var _has_cached_color: bool = false

const LANE_KEYS: Dictionary = {
	KEY_D: 0,
	KEY_J: 0,
	KEY_S: 1,
	KEY_K: 1,
}

@export var beatmap_path: String = ""
@export var bars_per_segment: int = 2
@export var win_condition: WinCondition = WinCondition.METER
@export var max_misses_for_catch: int = 1

@onready var notes_node: Node2D = $Notes
@onready var debug_label: Label = $DebugLabel
@onready var lane0: ColorRect = $Lanes/Lane0
@onready var lane1: ColorRect = $Lanes/Lane1
@onready var left_edge: ColorRect = $Lanes/LeftEdge
@onready var right_edge: ColorRect = $Lanes/RightEdge
@onready var center_divider: ColorRect = $Lanes/CenterDivider
@onready var target_line: ColorRect = $TargetLine
@onready var rhythm_ui: RhythmUI = $RhythmUI

var beatmap: Dictionary = {}
var all_notes: Array = []
var song_started: bool = false
var song_position: float = 0.0

var _lead_in: float = 0.25
var _last_note_offset: float = 0.0
var _segment_cutoff: float = 0.0

var pending_notes: Array = []
var active_notes: Array = []
var lane_front: Array = [null, null]
var combo: int = 0
var fish_caught: bool = false
var miss_count: int = 0
var npc_reel_component: ReelProgressComponent

func _ready() -> void:
	add_to_group("rhythm_battle")
	_update_lane_color()
	_position_lanes()

## Samples the background once (screen center, from the frame rendered just
## before this battle appeared) and only updates the cached lane color if
## it has drifted enough from last time — otherwise reuses the old one.
func _update_lane_color() -> void:
	var sampled := _sample_background_color()
	if not _has_cached_color or _color_distance(sampled, _cached_bg_color) > RESAMPLE_THRESHOLD:
		_cached_bg_color = sampled
		_has_cached_color = true
	var lane_color := _darkened(_cached_bg_color, LANE_DARKEN)
	var trim_color := _darkened(_cached_bg_color, TRIM_DARKEN)
	lane0.color = lane_color
	lane1.color = lane_color
	left_edge.color = trim_color
	right_edge.color = trim_color
	center_divider.color = trim_color

func _sample_background_color() -> Color:
	var img := get_viewport().get_texture().get_image()
	if img == null or img.get_width() == 0 or img.get_height() == 0:
		return _cached_bg_color
	return img.get_pixel(img.get_width() / 2, img.get_height() / 2)

func _color_distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()

func _darkened(color: Color, amount: float) -> Color:
	var result := color * (1.0 - amount)
	result.a = 1.0
	return result

func _load_beatmap() -> void:
	var file := FileAccess.open(beatmap_path, FileAccess.READ)
	if file == null:
		push_error("RhythmBattle: could not open beatmap at " + beatmap_path)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("RhythmBattle: JSON parse error")
		return
	beatmap = json.get_data()
	all_notes = beatmap["hit_objects"].duplicate(true)
	# note times stay in seconds, absolute within the beatmap's own loop —
	# a segment gets sliced out of this in start()
	for note in all_notes:
		note["time"] = note["time"] / 1000.0
	all_notes.sort_custom(func(a, b): return a["time"] < b["time"])
	print("Beatmap loaded: ", beatmap.get("title"), " | ", all_notes.size(), " notes total")

func setup(npc_reel: ReelProgressComponent) -> void:
	_load_beatmap()
	npc_reel_component = npc_reel
	if npc_reel_component:
		npc_reel_component.reset()
		npc_reel_component.reeled_in.connect(_on_fish_caught)
	rhythm_ui.setup(npc_reel_component)

## music_position: where the overworld/loop track currently is (seconds) —
## used to pick which bar-aligned segment of the beatmap to play.
func start(music_position: float) -> void:
	var bar_duration: float = (beatmap.get("ms_per_beat", 500.0) / 1000.0) * beatmap.get("meter", 4)
	var segment_duration: float = bar_duration * bars_per_segment
	var segment_start: float = ceil(music_position / bar_duration) * bar_duration
	_lead_in = segment_start - music_position
	if _lead_in < MIN_LEAD_IN:
		segment_start += bar_duration
		_lead_in += bar_duration

	_last_note_offset = PlayerData.note_offset
	pending_notes = all_notes.filter(func(n): return n["time"] >= segment_start and n["time"] < segment_start + segment_duration).duplicate(true)
	for note in pending_notes:
		note["time"] = (note["time"] - segment_start) + _lead_in + _last_note_offset

	song_position = 0.0
	_segment_cutoff = _lead_in + segment_duration
	song_started = true
	print("RhythmBattle: segment start=%.2fs | %d notes | cutoff at %.2fs" % [segment_start, pending_notes.size(), _segment_cutoff])

func _check_offset_change() -> void:
	if PlayerData.note_offset == _last_note_offset:
		return
	var delta := PlayerData.note_offset - _last_note_offset
	for note in pending_notes:
		note["time"] += delta
	_last_note_offset = PlayerData.note_offset
	print("Offset changed by: %+.0fms | new offset: %+.0fms | pending notes shifted: %d" % [delta * 1000, PlayerData.note_offset * 1000, pending_notes.size()])

func _position_lanes() -> void:
	var viewport_size := get_viewport_rect().size
	lane0.size = Vector2(LANE_SPACING, viewport_size.y)
	lane0.position = Vector2(_lane_x(0) - LANE_SPACING / 2.0, 0)
	lane1.size = Vector2(LANE_SPACING, viewport_size.y)
	lane1.position = Vector2(_lane_x(1) - LANE_SPACING / 2.0, 0)
	left_edge.size = Vector2(TRIM_WIDTH, viewport_size.y)
	left_edge.position = Vector2(PLAY_AREA_LEFT, 0)
	right_edge.size = Vector2(TRIM_WIDTH, viewport_size.y)
	right_edge.position = Vector2(PLAY_AREA_LEFT + PLAY_AREA_WIDTH - TRIM_WIDTH, 0)
	center_divider.size = Vector2(TRIM_WIDTH, viewport_size.y)
	center_divider.position = Vector2(PLAY_AREA_LEFT + PLAY_AREA_WIDTH / 2.0 - TRIM_WIDTH / 2.0, 0)
	target_line.size = Vector2(PLAY_AREA_WIDTH, 4.0)
	target_line.position = Vector2(PLAY_AREA_LEFT, TARGET_Y - 2.0)
	rhythm_ui.combo_label.position = Vector2(PLAY_AREA_LEFT + 10.0, TARGET_Y - 40.0)

func _process(delta: float) -> void:
	if not song_started:
		return
	_check_offset_change()
	var is_frozen := StateManager.current_state == StateManager.State.FROZEN
	if is_frozen:
		return
	song_position += delta
	var scroll_time: float = TARGET_Y / SCROLL_SPEED
	while pending_notes.size() > 0 and pending_notes[0]["time"] <= song_position + scroll_time:
		_spawn_note(pending_notes.pop_front())
	for note in active_notes:
		note.position.y = TARGET_Y - (note.hit_time - song_position) * SCROLL_SPEED
	for note in active_notes.duplicate():
		if song_position > note.hit_time + HIT_WINDOW_OK:
			_resolve_note(note, "MISS")
	if song_position >= _segment_cutoff and active_notes.is_empty() and song_started:
		_on_song_complete()
	if debug_label:
		debug_label.text = "pos: %.3fs | combo: %d | pending: %d | active: %d" % [song_position, combo, pending_notes.size(), active_notes.size()]

func _spawn_note(data: Dictionary) -> void:
	var note = NOTE_SCENE.instantiate()
	note.hit_time = data["time"]
	note.lane = data["lane"]
	note.position = Vector2(_lane_x(data["lane"]), TARGET_Y - (data["time"] - song_position) * SCROLL_SPEED)
	note.modulate = LANE_COLORS[data["lane"]]
	notes_node.add_child(note)
	active_notes.append(note)
	if lane_front[data["lane"]] == null:
		lane_front[data["lane"]] = note

func _lane_x(lane: int) -> float:
	var center_x: float = PLAY_AREA_LEFT + PLAY_AREA_WIDTH / 2.0
	return center_x - LANE_SPACING / 2.0 + lane * LANE_SPACING

func _input(event: InputEvent) -> void:
	if not song_started:
		return
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	if not LANE_KEYS.has(event.keycode):
		return
	_on_lane_input(LANE_KEYS[event.keycode])

	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			_restart()
		if event.keycode == KEY_BRACKETLEFT:
			PlayerData.note_offset -= 0.01
			print("note_offset: %+.0fms" % (PlayerData.note_offset * 1000))
		if event.keycode == KEY_BRACKETRIGHT:
			PlayerData.note_offset += 0.01
			print("note_offset: %+.0fms" % (PlayerData.note_offset * 1000))

func _on_lane_input(lane: int) -> void:
	_flash_target_line()
	_attempt_hit(lane)

func _flash_target_line() -> void:
	target_line.color = TARGET_LINE_FLASH
	var tween := create_tween()
	tween.tween_property(target_line, "color", TARGET_LINE_DEFAULT, 0.1)

func _attempt_hit(lane: int) -> void:
	var front = lane_front[lane]
	if front == null:
		return
	var delta_time: float = abs(front.hit_time - song_position)
	if delta_time <= HIT_WINDOW_PERFECT:
		_resolve_note(front, "PERFECT")
	elif delta_time <= HIT_WINDOW_OK:
		_resolve_note(front, "OK")

func _resolve_note(note: Node2D, result: String) -> void:
	active_notes.erase(note)
	lane_front[note.lane] = null
	for n in active_notes:
		if n.lane == note.lane:
			lane_front[note.lane] = n
			break
	if result == "MISS":
		note.queue_free()
		_on_miss()
	else:
		note.hit()  # handles its own queue_free after effects
		_on_hit()

func _on_hit() -> void:
	combo += 1
	var progress: int = int(BASE_DAMAGE * (1.0 + combo * BASE_COMBO_GROWTH))
	if not fish_caught and npc_reel_component:
		npc_reel_component.add_progress(progress)
	rhythm_ui.update_combo(combo)

func _on_miss() -> void:
	combo = 0
	miss_count += 1
	rhythm_ui.update_combo(combo)

func _on_fish_caught() -> void:
	fish_caught = true

func _on_song_complete() -> void:
	song_started = false
	var caught := fish_caught
	if win_condition == WinCondition.MISS_COUNT:
		caught = miss_count <= max_misses_for_catch
	battle_complete.emit(caught)

func _restart() -> void:
	song_started = false
	song_position = 0.0
	combo = 0
	fish_caught = false
	miss_count = 0
	active_notes.duplicate().map(func(n): n.queue_free())
	active_notes.clear()
	lane_front = [null, null]
	_load_beatmap()
	start(0.0)  # restart at the first segment, for testing
