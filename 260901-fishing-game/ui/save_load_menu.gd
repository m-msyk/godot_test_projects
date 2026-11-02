class_name SaveLoadMenu extends SaveMenuBase

func open_with_data() -> void:
	var meta := SaveManager.get_save_meta()
	if meta.is_empty():
		return
	populate(
		meta["current_floor"],
		meta["current_area"],
		meta["time_played_seconds"]
	)
	open()

func _on_primary_pressed() -> void:
	await ScreenFade.fade_to_black()
	get_tree().change_scene_to_file("res://floors/main.tscn")

func _on_secondary_pressed() -> void:
	close()
