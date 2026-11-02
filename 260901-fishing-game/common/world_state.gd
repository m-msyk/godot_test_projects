extends Node

signal flag_changed(flag_id: String, value: bool)

var flags: Dictionary = {}

func set_flag(flag_id: String, value: bool = true) -> void:
	flags[flag_id] = value
	flag_changed.emit(flag_id, value)

func get_flag(flag_id: String) -> bool:
	return flags.get(flag_id, false)

func reset() -> void:
	flags.clear()
