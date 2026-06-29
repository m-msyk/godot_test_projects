extends NPC

@onready var shop_component: ShopComponent = $ShopComponent

func _on_dialogic_signal(argument: String) -> void:
	super._on_dialogic_signal(argument)
	if argument == "shop_open":
		await Dialogic.timeline_ended
		shop_component.open_shop()
