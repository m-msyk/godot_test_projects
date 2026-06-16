class_name BaseDamageMod extends Mod

@export var damage_per_level: float = 2.0

func get_base_damage_bonus(level: int) -> float:
	return level * damage_per_level

func get_stat_display(level: int) -> String:
	return "Base DMG: %.1f" % (RhythmBattle.BASE_DAMAGE + get_base_damage_bonus(level))
