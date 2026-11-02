class_name Main extends Node

const FISH_BATTLE_BEATMAP := "res://rhythm/rhythm_battle_01_normal.json"
const FISH_CATCH_THRESHOLD: int = 200

@onready var current_level: Node = $CurrentLevel
@onready var elevator_ui: ElevatorUI = $ElevatorUI
@onready var save_confirm_menu: SaveConfirmMenu = $SaveConfirmMenu

var _current_battle: RhythmBattle = null
var _current_npc: NPC = null
var _current_fish_species: FishSpecies = null

func _ready() -> void:
	StateManager.initialize()
	await get_tree().process_frame
	_connect_signals()
	if SaveManager.save_exists():
		SaveManager.load_game()
		print("caught_fish: ", PlayerData.caught_fish)
		print("note_offset: ", (PlayerData.note_offset - 0.25) * 1000)
		_load_level_immediate(FloorManager.get_current_scene())
		_spawn_player_at_save_point()
	else:
		_load_level_immediate("b1_lobby")
	await ScreenFade.fade_from_black()

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

func _connect_fishing() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var fishing := player.get_node_or_null("FishingComponent") as FishingComponent
	if fishing and not fishing.fish_hooked.is_connected(_on_fish_hooked):
		fishing.fish_hooked.connect(_on_fish_hooked)

func _spawn_player_at_save_point() -> void:
	var meta := SaveManager.get_save_meta()
	var save_point_id: String = meta["save_point_id"]
	for sp in get_tree().get_nodes_in_group("save_point"):
		if sp.save_point_id == save_point_id:
			var player := get_tree().get_first_node_in_group("player")
			if player:
				player.global_position = sp.get_spawn_position()
			return

func _load_level_immediate(scene_name: String) -> void:
	var path := "res://floors/" + scene_name + ".tscn"
	var floor_id := scene_name.split("_")[0]
	FloorManager.set_current_floor(floor_id)
	for child in current_level.get_children():
		child.queue_free()
	current_level.add_child(load(path).instantiate())
	_connect_elevators()
	_connect_save_points()
	_connect_npcs()
	_connect_fishing()

## Battles overlay directly on top of the running world (with the overworld
## music continuing uninterrupted) instead of swapping to a separate scene.
func _load_battle_immediate(npc: NPC) -> void:
	_current_battle = load("res://rhythm/rhythm_battle.tscn").instantiate()
	_current_battle.beatmap_path = npc.battle_beatmap_path
	add_child(_current_battle)
	var npc_reel := npc.get_node_or_null("ReelProgressComponent") as ReelProgressComponent
	_current_battle.setup(npc_reel)
	_current_battle.battle_complete.connect(_on_battle_complete)

func _load_fish_battle_immediate() -> void:
	_current_battle = load("res://rhythm/rhythm_battle.tscn").instantiate()
	_current_battle.beatmap_path = FISH_BATTLE_BEATMAP
	_current_battle.win_condition = RhythmBattle.WinCondition.MISS_COUNT
	add_child(_current_battle)
	var fish_reel := ReelProgressComponent.new()
	fish_reel.catch_threshold = FISH_CATCH_THRESHOLD
	_current_battle.add_child(fish_reel)
	_current_battle.setup(fish_reel)
	_current_battle.battle_complete.connect(_on_battle_complete)

func _unload_battle() -> void:
	if _current_battle:
		_current_battle.queue_free()
		_current_battle = null
	StateManager.set_state(StateManager.State.FREE)

func _on_floor_selected(scene_name: String) -> void:
	await TransitionManager.run(func(): _load_level_immediate(scene_name))

func _on_elevator_opened() -> void:
	elevator_ui.open()

func _on_save_requested(save_point_id: String, floor_id: String, area: String) -> void:
	save_confirm_menu.open_with_data(save_point_id, floor_id, area)

func _start_battle(load_callable: Callable) -> void:
	var music_position := MusicManager.get_primary_position()
	load_callable.call()
	StateManager.set_state(StateManager.State.PARTIAL)
	_current_battle.start(music_position)

func _on_battle_requested(npc: NPC) -> void:
	_current_npc = npc
	_start_battle(func(): _load_battle_immediate(npc))

func _on_fish_hooked(species: FishSpecies) -> void:
	_current_fish_species = species
	_start_battle(func(): _load_fish_battle_immediate())

func _on_battle_complete(fish_caught: bool) -> void:
	if _current_npc:
		var outcome := "win" if fish_caught else "survive"
		_current_npc.start_battle_outcome_dialogue(outcome)
	elif _current_fish_species:
		var species := _current_fish_species
		_current_fish_species = null
		return_from_battle()
		if fish_caught:
			PlayerData.catch_fish(species.id, species.roll_length_cm())
		var player := get_tree().get_first_node_in_group("player")
		var fishing := player.get_node_or_null("FishingComponent") as FishingComponent
		if fishing:
			fishing.finish_battle(fish_caught, species)

func _on_battle_scene_end_requested() -> void:
	return_from_battle()
	_current_npc = null

func return_from_battle() -> void:
	_unload_battle()
