class_name ComboMultiplierMod extends Mod

@export var growth_per_level: float = 0.02

func get_combo_growth_bonus(level: int) -> float:
	return level * growth_per_level

func get_stat_display(level: int) -> String:
	return "Combo Growth: %.2f" % (RhythmBattle.BASE_COMBO_GROWTH + get_combo_growth_bonus(level))
