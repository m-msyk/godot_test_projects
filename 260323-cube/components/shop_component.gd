class_name ShopComponent extends Node

signal shop_requested()

func open_shop() -> void:
	shop_requested.emit()
