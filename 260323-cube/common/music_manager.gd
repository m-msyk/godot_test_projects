extends Node

var _player: Node3D = null
var _areas: Dictionary = {}

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

func crossfade_to(incoming: AudioStreamPlayer, duration: float = 0.2) -> void:
	incoming.volume_db = -80.0
	incoming.play()
	var tween := create_tween()
	for audio_player in _areas.values():
		tween.parallel().tween_property(audio_player, "volume_db", -80.0, duration)
	tween.parallel().tween_property(incoming, "volume_db", 0.0, duration)
	await tween.finished
	stop_all()
