extends WorldEnvironment

func _process(delta):
	var ground_color = environment.sky.sky_material.ground_bottom_color
	get_tree().call_group("poche", "update_poche_color", ground_color)
