extends Node

var _player: Node3D = null

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	for area in get_tree().get_nodes_in_group("music_area"):
		area.update_volume(_player.global_position)
