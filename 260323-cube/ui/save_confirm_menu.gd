class_name SaveConfirmMenu extends SaveMenuBase

var _save_point_id: String
var _floor: String
var _area: String

func open_with_data(save_point_id: String, floor_id: String, area: String) -> void:
	_save_point_id = save_point_id
	_floor = floor_id
	_area = area
	populate(floor_id, area, PlayerData.time_played_seconds)
	open()
	StateManager.set_state(StateManager.State.FROZEN)

func _on_primary_pressed() -> void:
	SaveManager.save_game(_save_point_id, _floor, _area)
	close()
	StateManager.set_state(StateManager.State.FREE)

func _on_secondary_pressed() -> void:
	close()
	StateManager.set_state(StateManager.State.FREE)
