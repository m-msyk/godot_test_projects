class_name MaxHealthMod extends Mod

@export var health_per_level: int = 5

func get_max_health_bonus(level: int) -> int:
	return level * health_per_level

func get_stat_display(level: int) -> String:
	var bonus := level * health_per_level
	return "%d (+%d)" % [RhythmBattle.BASE_HEALTH + bonus, bonus]
