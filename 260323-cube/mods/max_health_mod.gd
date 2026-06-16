class_name MaxHealthMod extends Mod

@export var health_per_level: int = 5

func get_max_health_bonus(level: int) -> int:
	return level * health_per_level

func get_stat_display(level: int) -> String:
	return "Max HP: %d" % (RhythmBattle.BASE_HEALTH + get_max_health_bonus(level))
