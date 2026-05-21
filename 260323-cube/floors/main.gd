class_name Main extends Node

@onready var current_level: Node = $CurrentLevel
@onready var elevator_ui: ElevatorUI = $ElevatorUI
@onready var save_confirm_menu: SaveConfirmMenu = $SaveConfirmMenu


func _ready() -> void:
	StateManager.initialize()
	await get_tree().process_frame
	_connect_signals()
	if SaveManager.save_exists():
		SaveManager.load_game()
		_load_level_immediate("res://floors/" + FloorManager.current_floor + ".tscn")
		_spawn_player_at_save_point()
	else:
		_load_level_immediate("res://floors/b1.tscn")
	await ScreenFade.fade_from_black()

func _connect_signals() -> void:
	elevator_ui.floor_selected.connect(_on_floor_selected)

func _connect_elevators() -> void:
	print("Connecting elevators, interactables: ", get_tree().get_nodes_in_group("interactable"))
	for elevator in get_tree().get_nodes_in_group("interactable"):
		if elevator is Elevator:
			print("Found elevator: ", elevator.name)
			if not elevator.elevator_opened.is_connected(_on_elevator_opened):
				elevator.elevator_opened.connect(_on_elevator_opened)

func _spawn_player_at_save_point() -> void:
	var meta := SaveManager.get_save_meta()
	var save_point_id: String = meta["save_point_id"]
	for sp in get_tree().get_nodes_in_group("save_point"):
		if sp.save_point_id == save_point_id:
			var player := get_tree().get_first_node_in_group("player")
			if player:
				player.global_position = sp.get_spawn_position()
			return

func _on_floor_selected(floor_id: String) -> void:
	load_level("res://floors/" + floor_id + ".tscn")

func _on_elevator_opened() -> void:
	print("elevator_opened received")
	elevator_ui.open()

func _load_level_immediate(path: String) -> void:
	FloorManager.set_current_floor(path.get_file().get_basename())
	for child in current_level.get_children():
		child.queue_free()
	var level = load(path)
	current_level.add_child(level.instantiate())
	_connect_elevators()
	_connect_save_points()

func load_level(path: String) -> void:
	StateManager.set_state(StateManager.State.PARTIAL)
	await ScreenFade.fade_to_black()
	_load_level_immediate(path)
	await ScreenFade.fade_from_black()
	StateManager.set_state(StateManager.State.FREE)

func _connect_save_points() -> void:
	for sp in get_tree().get_nodes_in_group("save_point"):
		if not sp.save_requested.is_connected(_on_save_requested):
			sp.save_requested.connect(_on_save_requested)

func _on_save_requested(save_point_id: String, floor_id: String, area: String) -> void:
	save_confirm_menu.open_with_data(save_point_id, floor_id, area)
