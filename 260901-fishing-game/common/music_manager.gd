extends Node

const MENU_FILTER_LOWPASS_HZ: float = 900.0
const MENU_FILTER_BYPASS_HZ: float = 20000.0
const MENU_FILTER_CHORUS_WET: float = 0.3
const MENU_FILTER_TWEEN_DURATION: float = 0.5

var _player: Node3D = null
var _areas: Dictionary = {}

var _lowpass: AudioEffectLowPassFilter
var _chorus: AudioEffectChorus
var _filter_tween: Tween

func _ready() -> void:
	# Music (and the playback position it's read from for loop/bar timing)
	# must keep running through the pause menu, so it stays unpaused too.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_menu_filter()

func _setup_menu_filter() -> void:
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx == -1:
		return
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = MENU_FILTER_BYPASS_HZ
	AudioServer.add_bus_effect(bus_idx, _lowpass)

	_chorus = AudioEffectChorus.new()
	_chorus.wet = 0.0
	AudioServer.add_bus_effect(bus_idx, _chorus)

## Tweens the Music bus toward (or away from) a muffled lowpass + a slight
## chorus/flanger swirl, used to signal "the menu is up" without touching
## playback itself.
func set_menu_filter_active(active: bool) -> void:
	if _lowpass == null or _chorus == null:
		return
	if _filter_tween:
		_filter_tween.kill()
	_filter_tween = create_tween()
	_filter_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_filter_tween.set_parallel(true)
	var target_cutoff := MENU_FILTER_LOWPASS_HZ if active else MENU_FILTER_BYPASS_HZ
	var target_wet := MENU_FILTER_CHORUS_WET if active else 0.0
	_filter_tween.tween_property(_lowpass, "cutoff_hz", target_cutoff, MENU_FILTER_TWEEN_DURATION)
	_filter_tween.tween_property(_chorus, "wet", target_wet, MENU_FILTER_TWEEN_DURATION)

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	for path in _areas:
		var audio_player: AudioStreamPlayer = _areas[path]
		for area in get_tree().get_nodes_in_group("music_area"):
			if area.stream != null and area.stream.resource_path == path:
				var influence: float = area.calculate_influence(_player.global_position)
				audio_player.volume_db = linear_to_db(influence) if influence > 0.0 else -80.0
				break

func register(area: MusicArea) -> void:
	if area.stream == null:
		return
	var path := area.stream.resource_path
	if _areas.has(path):
		return
	var audio_player := AudioStreamPlayer.new()
	audio_player.stream = area.stream
	audio_player.bus = "Music"
	audio_player.volume_db = -80.0
	add_child(audio_player)
	_areas[path] = audio_player
	var stream_length := area.stream.get_length()
	var seek_pos := fmod(get_primary_position(), stream_length) if stream_length > 0.0 else 0.0
	audio_player.play(seek_pos)

func unregister(area: MusicArea) -> void:
	if area.stream == null:
		return
	var path := area.stream.resource_path
	if not _areas.has(path):
		return
	for active_area in get_tree().get_nodes_in_group("music_area"):
		if active_area != area and active_area.stream != null and active_area.stream.resource_path == path:
			return
	var audio_player: AudioStreamPlayer = _areas[path]
	audio_player.queue_free()
	_areas.erase(path)

func get_primary_position() -> float:
	if _areas.is_empty():
		return 0.0
	return (_areas.values()[0] as AudioStreamPlayer).get_playback_position()

func get_primary_length() -> float:
	if _areas.is_empty():
		return 0.0
	return (_areas.values()[0] as AudioStreamPlayer).stream.get_length()

func stop_all() -> void:
	for audio_player in _areas.values():
		audio_player.stop()

func resume_all() -> void:
	for audio_player in _areas.values():
		audio_player.play()

func crossfade_to(incoming: AudioStreamPlayer, duration: float = 0.2, start_position: float = 0.0) -> void:
	incoming.volume_db = -80.0
	incoming.play(start_position)
	var tween := create_tween()
	for audio_player in _areas.values():
		tween.parallel().tween_property(audio_player, "volume_db", -80.0, duration)
	tween.parallel().tween_property(incoming, "volume_db", 0.0, duration)
	await tween.finished
	stop_all()
