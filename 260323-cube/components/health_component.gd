class_name HealthComponent extends Node

signal health_changed(current: int, maximum: int)
signal defeated()

@export var max_health: int = 30

var current_health: int

func _ready() -> void:
	current_health = max_health

func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		defeated.emit()

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
