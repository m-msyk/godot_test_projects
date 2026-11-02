extends NPC

@onready var shop_component: ShopComponent = $ShopComponent

var _pending_shop: bool = false

func _on_dialogic_signal(argument: String) -> void:
	super._on_dialogic_signal(argument)
	if argument == "shop_open":
		_pending_shop = true

func _on_dialogue_ended() -> void:
	super._on_dialogue_ended()
	if _pending_shop:
		_pending_shop = false
		shop_component.open_shop()
