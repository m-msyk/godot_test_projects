class_name Mod extends Resource

@export var mod_id: String
@export var display_name: String
@export var description: String
@export var base_cost: int = 20
@export var cost_scaling: float = 2.0

func get_cost(times_purchased: int) -> int:
	return int(base_cost * pow(cost_scaling, times_purchased))

func get_stat_display(level: int) -> String:
	return ""

func on_battle_start(battle: RhythmBattle) -> void:
	pass

func on_hit(battle: RhythmBattle) -> void:
	pass

func on_miss(battle: RhythmBattle) -> void:
	pass

func on_song_complete(battle: RhythmBattle) -> void:
	pass

func get_base_damage_bonus(level: int) -> float:
	return 0.0

func get_combo_growth_bonus(level: int) -> float:
	return 0.0

func get_max_health_bonus(level: int) -> int:
	return 0
