## 

class_name Main extends Node

@onready var current_level: Node = $CurrentLevel
@onready var elevator_ui: ElevatorUI = $ElevatorUI
@onready var save_confirm_menu: SaveConfirmMenu = $SaveConfirmMenu

var _current_battle: RhythmBattle = null
var _current_npc: NPC = null

var _pre_battle_player_position: Vector3 # Saves player position to know where to return to after battle

## Calls [method SaveManager.load_game].
func _ready() -> void:
	StateManager.initialize()
	await get_tree().process_frame
	_connect_signals()
	if SaveManager.save_exists():
		SaveManager.load_game()
		_load_level_immediate(FloorManager.current_floor)
		_spawn_player_at_save_point()
	else:
		_load_level_immediate("b1")
	await ScreenFade.fade_from_black()

## Connects to signals emitted by [ElevatorUI.floor_selected]
func _connect_signals() -> void:
	elevator_ui.floor_selected.connect(_on_floor_selected)

func _connect_elevators() -> void:
	for elevator in get_tree().get_nodes_in_group("interactable"):
		if elevator is Elevator:
			if not elevator.elevator_opened.is_connected(_on_elevator_opened):
				elevator.elevator_opened.connect(_on_elevator_opened)

func _connect_save_points() -> void:
	for sp in get_tree().get_nodes_in_group("save_point"):
		if not sp.save_requested.is_connected(_on_save_requested):
			sp.save_requested.connect(_on_save_requested)

func _connect_npcs() -> void:
	for npc in get_tree().get_nodes_in_group("interactable"):
		if npc is NPC:
			if not npc.battle_requested.is_connected(_on_battle_requested):
				npc.battle_requested.connect(_on_battle_requested)
			if not npc.battle_scene_end_requested.is_connected(_on_battle_scene_end_requested):
				npc.battle_scene_end_requested.connect(_on_battle_scene_end_requested)

func _spawn_player_at_save_point() -> void:
	var meta := SaveManager.get_save_meta()
	var save_point_id: String = meta["save_point_id"]
	for sp in get_tree().get_nodes_in_group("save_point"):
		if sp.save_point_id == save_point_id:
			var player := get_tree().get_first_node_in_group("player")
			if player:
				player.global_position = sp.get_spawn_position()
			return

func _load_level_immediate(floor_id: String) -> void:
	var path := "res://floors/" + floor_id + ".tscn"
	FloorManager.set_current_floor(floor_id)
	for child in current_level.get_children():
		child.queue_free()
	current_level.add_child(load(path).instantiate())
	_connect_elevators()
	_connect_save_points()
	_connect_npcs()

func _load_battle_immediate(npc: NPC) -> void:
	var player := get_tree().get_first_node_in_group("player")
	_pre_battle_player_position = player.global_position
	for child in current_level.get_children():
		child.hide()
	_current_battle = load("res://rhythm/rhythm_battle.tscn").instantiate()
	_current_battle.beatmap_path = npc.battle_beatmap_path
	_current_battle.audio_path = npc.battle_song_path
	add_child(_current_battle)
	var player_hc := player.get_node("HealthComponent")
	_current_battle.setup(player_hc, npc.health_component)
	_current_battle.player_defeated.connect(_on_player_defeated)
	_current_battle.battle_complete.connect(_on_battle_complete)

func _unload_battle() -> void:
	if _current_battle:
		_current_battle.queue_free()
		_current_battle = null
	for child in current_level.get_children():
		child.show()
	var player := get_tree().get_first_node_in_group("player")
	player.global_position = _pre_battle_player_position
	MusicManager.resume_all()

func _on_floor_selected(floor_id: String) -> void:
	await TransitionManager.run(func(): _load_level_immediate(floor_id))

func _on_elevator_opened() -> void:
	elevator_ui.open()

func _on_save_requested(save_point_id: String, floor_id: String, area: String) -> void:
	save_confirm_menu.open_with_data(save_point_id, floor_id, area)

func _on_battle_requested(npc: NPC) -> void:
	_current_npc = npc
	var loop_length := MusicManager.get_primary_length()
	var snapshot_position := MusicManager.get_primary_position()
	var transition_start := Time.get_ticks_msec()
	await TransitionManager.run(func(): _load_battle_immediate(npc))
	var transition_duration := (Time.get_ticks_msec() - transition_start) / 1000.0
	var actual_position := fmod(snapshot_position + transition_duration, loop_length)
	var time_remaining := loop_length - actual_position
	if time_remaining < 1.0:
		time_remaining += loop_length
	_current_battle.start(time_remaining)

func _on_battle_complete(npc_defeated: bool) -> void:
	if _current_npc:
		var outcome := "win" if npc_defeated else "survive"
		_current_npc.start_battle_outcome_dialogue(outcome)

func _on_battle_scene_end_requested() -> void:
	print("battle_scene_end_requested received")
	await return_from_battle()
	_current_npc = null

func _on_player_defeated() -> void:
	if _current_npc:
		_current_npc.start_battle_outcome_dialogue("lose")

func return_from_battle() -> void:
	await TransitionManager.run(func(): _unload_battle())
