class_name ComboMultiplierMod extends Mod

@export var growth_per_level: float = 0.02

func get_combo_growth_bonus(level: int) -> float:
	return level * growth_per_level

func get_stat_display(level: int) -> String:
	var bonus := level * growth_per_level
	return "%.2f (+%.2f)" % [RhythmBattle.BASE_COMBO_GROWTH + bonus, bonus]
