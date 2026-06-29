class_name RhythmBattle extends Node2D

signal player_defeated()
signal battle_complete(npc_defeated: bool)

const NOTE_SCENE = preload("res://rhythm/note.tscn")

const SCROLL_SPEED: float = 300.0
const TARGET_X: float = 50.0
const HIT_WINDOW_PERFECT: float = 0.050
const HIT_WINDOW_OK: float = 0.100
const LANE_SPACING: float = 80.0
const CROSSFADE_DURATION: float = 0.01
const LANE_COLORS: Array = [Color(0.2, 0.4, 1.0), Color(1.0, 0.2, 0.2)]
const TARGET_LINE_DEFAULT: Color = Color(1.0, 1.0, 1.0)
const TARGET_LINE_FLASH: Color = Color(1.0, 1.0, 0.0)

const BASE_HEALTH: int = 30
const BASE_DAMAGE: float = 2.0
const BASE_COMBO_GROWTH: float = 0.05
const HIT_RECOVERY: int = 1
const MISS_DAMAGE: int = 3

const LANE_KEYS: Dictionary = {
	KEY_F: 0,
	KEY_J: 0,
	KEY_D: 1,
	KEY_K: 1,
}

@export var beatmap_path: String = ""
@export var audio_path: String = ""

@onready var notes_node: Node2D = $Notes
@onready var debug_label: Label = $DebugLabel
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var lane0: ColorRect = $Lanes/Lane0
@onready var lane1: ColorRect = $Lanes/Lane1
@onready var target_line: ColorRect = $TargetLine
@onready var rhythm_ui: RhythmUI = $RhythmUI

var beatmap: Dictionary = {}
var song_started: bool = false
var song_position: float = 0.0

var _lead_in: float = 0.25
var _last_note_offset: float = 0.0

var pending_notes: Array = []
var active_notes: Array = []
var lane_front: Array = [null, null]
var combo: int = 0
var npc_defeated: bool = false
var player_health_component: HealthComponent
var npc_health_component: HealthComponent

# exposed for mods to read/write
var damage_blocks_remaining: int = 0
var perfect_run: bool = true
var last_milestone: int = 0

func _ready() -> void:
	add_to_group("rhythm_battle")
	_position_lanes()

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
	pending_notes = beatmap["hit_objects"].duplicate()
	# note times stay in seconds with no offset — applied in start()
	for note in pending_notes:
		note["time"] = note["time"] / 1000.0
	pending_notes.sort_custom(func(a, b): return a["time"] < b["time"])
	print("Beatmap loaded: ", beatmap.get("title"), " | ", pending_notes.size(), " notes")

func _setup_audio() -> void:
	var stream := load(audio_path)
	if stream == null:
		push_error("RhythmBattle: could not load audio at " + audio_path)
		return
	audio_player.stream = stream

func setup(player_hc: HealthComponent, npc_hc: HealthComponent) -> void:
	_load_beatmap()
	_setup_audio()
	player_health_component = player_hc
	npc_health_component = npc_hc
	player_health_component.max_health = PlayerData.get_max_health()
	player_health_component.reset()
	if npc_health_component:
		npc_health_component.reset()
		npc_health_component.defeated.connect(_on_npc_defeated)
	player_health_component.defeated.connect(_on_player_defeated)
	rhythm_ui.setup(player_hc, npc_hc)
	# setup mods
	for mod in PlayerData.MODS:
		if PlayerData.upgrades.get(mod.mod_id, 0) > 0:
			mod.on_battle_start(self)

func start(lead_in: float) -> void:
	_lead_in = lead_in
	_last_note_offset = PlayerData.note_offset
	for note in pending_notes:
		note["time"] += _lead_in + _last_note_offset
	song_position = 0.0
	song_started = true
	var crossfade_at := lead_in - CROSSFADE_DURATION
	if crossfade_at > 0.0:
		await get_tree().create_timer(crossfade_at).timeout
	MusicManager.crossfade_to(audio_player, CROSSFADE_DURATION)

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
	lane0.size = Vector2(viewport_size.x, 60.0)
	lane0.position = Vector2(0, _lane_y(0) - 30.0)
	lane1.size = Vector2(viewport_size.x, 60.0)
	lane1.position = Vector2(0, _lane_y(1) - 30.0)
	target_line.size = Vector2(4.0, LANE_SPACING + 60.0)
	target_line.position = Vector2(TARGET_X - 2.0, _lane_y(0) - 30.0)
	rhythm_ui.combo_label.position = Vector2(TARGET_X - 10.0, _lane_y(0) - 50.0)

func _process(delta: float) -> void:
	if not song_started:
		return
	_check_offset_change()
	var is_frozen := StateManager.current_state == StateManager.State.FROZEN
	audio_player.stream_paused = is_frozen
	if is_frozen:
		return
	song_position += delta
	var scroll_time: float = (get_viewport_rect().size.x - TARGET_X) / SCROLL_SPEED
	while pending_notes.size() > 0 and pending_notes[0]["time"] <= song_position + scroll_time:
		_spawn_note(pending_notes.pop_front())
	for note in active_notes:
		note.position.x = TARGET_X + (note.hit_time - song_position) * SCROLL_SPEED
	for note in active_notes.duplicate():
		if song_position > note.hit_time + HIT_WINDOW_OK:
			_resolve_note(note, "MISS")
	if pending_notes.is_empty() and active_notes.is_empty() and song_started:
		_on_song_complete()
	if debug_label:
		debug_label.text = "pos: %.3fs | combo: %d | pending: %d | active: %d" % [song_position, combo, pending_notes.size(), active_notes.size()]

func _spawn_note(data: Dictionary) -> void:
	var note = NOTE_SCENE.instantiate()
	note.hit_time = data["time"]
	note.lane = data["lane"]
	note.position = Vector2(TARGET_X + (data["time"] - song_position) * SCROLL_SPEED, _lane_y(data["lane"]))
	note.modulate = LANE_COLORS[data["lane"]]
	notes_node.add_child(note)
	active_notes.append(note)
	if lane_front[data["lane"]] == null:
		lane_front[data["lane"]] = note

func _lane_y(lane: int) -> float:
	var center_y: float = get_viewport_rect().size.y / 2.0
	return center_y - LANE_SPACING / 2.0 + lane * LANE_SPACING

func _lane_position(lane: int) -> Vector2:
	return Vector2(0, _lane_y(lane))

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
	var damage: int = int(PlayerData.get_base_damage() * (1.0 + combo * PlayerData.get_combo_growth_rate()))
	if npc_defeated:
		PlayerData.add_rhythm_points(damage)
	else:
		npc_health_component.take_damage(damage)
	player_health_component.heal(HIT_RECOVERY)
	rhythm_ui.update_combo(combo)
	for mod in PlayerData.MODS:
		if PlayerData.upgrades.get(mod.mod_id, 0) > 0:
			mod.on_hit(self)

func _on_miss() -> void:
	perfect_run = false
	combo = 0
	if damage_blocks_remaining > 0:
		damage_blocks_remaining -= 1
		print("Damage blocked! Blocks remaining: ", damage_blocks_remaining)
	else:
		player_health_component.take_damage(MISS_DAMAGE)
	rhythm_ui.update_combo(combo)
	for mod in PlayerData.MODS:
		if PlayerData.upgrades.get(mod.mod_id, 0) > 0:
			mod.on_miss(self)

func _on_player_health_changed(current: int, maximum: int) -> void:
	rhythm_ui._on_player_health_changed(current, maximum)

func _on_npc_health_changed(current: int, maximum: int) -> void:
	rhythm_ui._on_npc_health_changed(current, maximum)

func _on_player_defeated() -> void:
	song_started = false
	player_defeated.emit()

func _on_npc_defeated() -> void:
	npc_defeated = true

func _on_song_complete() -> void:
	song_started = false
	for mod in PlayerData.MODS:
		if PlayerData.upgrades.get(mod.mod_id, 0) > 0:
			mod.on_song_complete(self)
	battle_complete.emit(npc_defeated)

func _restart() -> void:
	song_started = false
	song_position = 0.0
	combo = 0
	npc_defeated = false
	active_notes.duplicate().map(func(n): n.queue_free())
	active_notes.clear()
	lane_front = [null, null]
	_load_beatmap()
	audio_player.stop()
	start(2.0)  # fixed lead_in for testing
